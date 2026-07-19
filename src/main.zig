const zm = @import("zm");
const std = @import("std");
const builtin = @import("builtin");

const renderer = zm.renderer;
const Args = zm.args;

const ts = zm.tree_sitter;
const Language = ts.Language;
const Parser = ts.Parser;
const ts_zm = zm.tree_sitter_zm;

const ts_symbols = zm.ts_symbols;

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
            std.log.info("Refer to docs for usage", .{});
            return;
        },
        error.MissingInputFilePath => {
            std.log.err("Input file not provided", .{});
            std.log.info("Refer to docs for usage", .{});
            return;
        },
        else => unreachable,
    };

    const file_stat = try std.Io.Dir.cwd().statFile(init.io, args.input.?, .{});
    const source = try std.Io.Dir.cwd().readFileAlloc(init.io, args.input.?, allocator, .limited(file_stat.size + 1));
    defer allocator.free(source);

    const frontmatter_end = zm.utils.splitFrontmatter(source) catch {
        // TODO: write to stderr instead
        std.debug.print("Unclosed frontmatter in the given input file.", .{});
        return;
    };
    const is_valid_kdl = try zm.utils.isValidKdl(allocator, source[0..frontmatter_end]);
    if (!is_valid_kdl) {
        // TODO: write to stderr instead
        std.debug.print("Syntax Errors in frontmatter", .{});
    }

    ts.setAllocator(ts_allocator);
    defer ts.setAllocator(null);

    const parser = Parser.create();
    defer parser.destroy();

    const lang: *const ts.Language = Language.fromRaw(ts_zm.language());
    defer lang.destroy();

    try parser.setLanguage(lang);
    const tree = parser.parseString(source[frontmatter_end..], null) orelse {
        return error.FailedToParse;
    };
    defer tree.destroy();

    //------------------
    var buf: [2000]u8 = undefined;
    var file_writer = std.Io.File.stderr().writer(init.io, &buf);
    const writer = &file_writer.interface;

    var render = renderer.HTMLRenderer{
        .allocator = allocator,
        .writer = writer,
        .source = source[frontmatter_end..],
        .frontmatter = source[4..(frontmatter_end-4)],
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
