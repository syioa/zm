const zm = @import("zm");
const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");

const renderer = zm.renderer;
const Args = zm.args;

const ts = zm.tree_sitter;
const Language = ts.Language;
const Parser = ts.Parser;
const ts_zm = zm.tree_sitter_zm;

const ts_symbols = zm.ts_symbols;

const utils = zm.utils;

fn print_help_message(writer: *std.Io.Writer) !void {
    try writer.print(
        \\zm {s}
        \\The cli for zm markup language
        \\
        \\{s} zm [OPTIONS] <INPUT_FILE_NAME>
        \\
        \\{s}
        \\    -h, --help             Print help information
        \\    -o, --output <path>    Print the generated HTML file
        \\    -s, --stdout           Print the HTML to stdout
        \\    -v, --version          Print program version
        \\
    , .{
        build_options.version,
        "\x1b[1m\x1b[4mUSAGE:\x1b[0m",
        "\x1b[1m\x1b[4mOPTIONS:\x1b[0m",
    });
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    // NOTE: ts_allocator is to be used only with tree sitter
    const is_debug_mode = (builtin.mode == .Debug or builtin.mode == .ReleaseSafe);
    var ts_gpa: if (is_debug_mode) std.heap.DebugAllocator(.{}) else void =
        if (is_debug_mode) std.heap.DebugAllocator(.{}){} else {};
    defer if (builtin.mode == .Debug) {
        _ = ts_gpa.deinit();
    };
    const ts_allocator: std.mem.Allocator = switch (builtin.mode) {
        .Debug, .ReleaseSafe => ts_gpa.allocator(),
        .ReleaseFast => std.heap.smp_allocator,
        .ReleaseSmall => std.heap.c_allocator,
    };

    var args_iterator = try init.minimal.args.iterateAllocator(allocator);
    defer args_iterator.deinit();
    const args = Args.parseArgs(&args_iterator) catch |err| switch (err) {
        error.MissingOutputFilePath => {
            std.log.err("Output File not provided", .{});
            std.log.info("For usage, try '--help'", .{});
            return;
        },
        error.MissingInputFilePath => {
            std.log.err("Input file not provided", .{});
            std.log.info("For usage, try '--help'", .{});
            return;
        },
        error.UnexpectedArguments => {
            std.log.err("Unexpected Argument(s)", .{});
            std.log.info("For usage, try '--help'", .{});
            return;
        },
        else => unreachable,
    };

    var stdout_buf: [512]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &stdout_buf);
    const stdout_writer = &stdout.interface;

    var stderr_buf: [512]u8 = undefined;
    var stderr = std.Io.File.stdout().writer(init.io, &stderr_buf);
    const stderr_writer = &stderr.interface;

    if (args.help) {
        try print_help_message(stdout_writer);
        try stdout_writer.flush();
        return;
    } else if (args.version) {
        try stdout_writer.print("v{s}\n", .{build_options.version});
        return;
    } else if (args.output == null and args.input != null) {
        std.log.info("You forgot to provide the output file name", .{});
        return;
    } else if (args.output == null) {
        return;
    }

    const file_stat = try std.Io.Dir.cwd().statFile(init.io, args.input.?, .{});
    const source = try std.Io.Dir.cwd().readFileAlloc(init.io, args.input.?, allocator, .limited(file_stat.size + 1));
    defer allocator.free(source);

    const fm_end = zm.utils.splitFrontmatter(source) catch {
        std.log.err("Unclosed frontmatter in the given input file.\n", .{});
        return;
    };
    const fm_start: usize = if (fm_end > 0) 4 else 0;
    const is_valid_kdl = try zm.utils.isValidKdl(allocator, source[0..fm_end]);
    if (!is_valid_kdl) {
        std.log.err("Syntax Errors in frontmatter", .{});
        return;
    }

    ts.setAllocator(ts_allocator);
    defer ts.setAllocator(null);

    const parser = Parser.create();
    defer parser.destroy();

    const lang: *const ts.Language = Language.fromRaw(ts_zm.language());
    defer lang.destroy();

    try parser.setLanguage(lang);
    const tree = parser.parseString(source[fm_end..], null) orelse {
        return error.FailedToParse;
    };
    defer tree.destroy();

    if (tree.rootNode().hasError()) {
        // TODO: also provide with proper line number where the error occurred
        std.log.err("Syntax Errors in Markup", .{});
        try utils.printError(&tree.rootNode(), source[fm_end..], stderr_writer);
        try stderr_writer.flush();
        return;
    }

    if (args.stdout) {
        var buf: [2048]u8 = undefined;
        var big_stdout_writer = std.Io.File.stdout().writer(init.io, &buf);
        const writer = &big_stdout_writer.interface;

        var render = renderer.HTMLRenderer{
            .allocator = allocator,
            .writer = writer,
            .source = source[fm_end..],
            .frontmatter = source[fm_start..(fm_end - fm_start)],
            .tree = tree,
            .ts_kinds = &ts_symbols.Symbols.init(lang),
            .stack = try std.ArrayList(renderer.OpenTag).initCapacity(allocator, @intCast(try std.math.divCeil(u32, tree.rootNode().descendantCount(), 3))),
            .list_state = .{
                .numbering = try std.ArrayList(u32).initCapacity(allocator, 10),
                .modes = try std.ArrayList(renderer.ListMode).initCapacity(allocator, 10),
            },
        };

        try render.render();

        try writer.flush();
    } else {
        var output_file = try std.Io.Dir.cwd().createFile(init.io, args.output.?, .{});
        defer output_file.close(init.io);

        var buf: [2048]u8 = undefined;
        var file_writer = output_file.writer(init.io, &buf);
        const writer = &file_writer.interface;

        var render = renderer.HTMLRenderer{
            .allocator = allocator,
            .writer = writer,
            .source = source[fm_end..],
            .frontmatter = source[fm_start..(fm_end - fm_start)],
            .tree = tree,
            .ts_kinds = &ts_symbols.Symbols.init(lang),
            .stack = try std.ArrayList(renderer.OpenTag).initCapacity(allocator, @intCast(try std.math.divCeil(u32, tree.rootNode().descendantCount(), 3))),
            .list_state = .{
                .numbering = try std.ArrayList(u32).initCapacity(allocator, 10),
                .modes = try std.ArrayList(renderer.ListMode).initCapacity(allocator, 10),
            },
        };

        try render.render();

        try writer.flush();
    }
}
