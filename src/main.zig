const zm = @import("zm");
const std = @import("std");

const renderer = zm.render;
const Args = zm.args;
const Token = zm.tokenizer.Token;
const TokenType = zm.tokenizer.TokenType;
const Tokenizer = zm.tokenizer.Tokenizer;
const Node = zm.AST.Node;
const Parser = zm.parser.Parser;
const OpenNode = renderer.OpenNode;

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();
    const allocator = arena.allocator();
    // const allocator = init.gpa;

    var args_iterator = try init.minimal.args.iterateAllocator(init.gpa);
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
    const source = try std.Io.Dir.cwd().readFileAlloc(init.io, args.input.?, init.gpa, .limited(file_stat.size + 1));
    defer init.gpa.free(source);

    // Tokenize
    var tokenizer = Tokenizer{ .input = source };
    var token_list = try std.ArrayList(Token).initCapacity(allocator, 10);
    defer token_list.deinit(allocator);

    while (tokenizer.next()) |token| {
        try token_list.append(allocator, token);
    }

    // Parse into DOD Flat Array
    var parser = Parser{
        .allocator = allocator,
        .tokens = token_list.items,
        .nodes = try std.ArrayList(Node).initCapacity(allocator, 10),
        .heading_payloads = try std.ArrayList(Node.heading).initCapacity(allocator, 10),
        .text_payloads = try std.ArrayList(Node.text).initCapacity(allocator, 10),
        .link_payloads = try std.ArrayList(Node.link).initCapacity(allocator, 5),
        .uli_payloads = try std.ArrayList(Node.unordered_list_item).initCapacity(allocator, 5),
    };
    defer parser.deinit();

    // root_idx is just a u32 pointing to index 0
    const root_idx = try parser.parse();
    _ = root_idx;

    var buf: [2000]u8 = undefined;
    var file_writer = std.Io.File.stdout().writer(init.io, &buf);
    const writer = &file_writer.interface;

    var render = renderer.HTMLRenderer {
        .allocator = allocator,
        .nodes = parser.nodes.items,
        .heading_payloads = parser.heading_payloads.items,
        .link_payloads = parser.link_payloads.items,
        .text_payloads = parser.text_payloads.items,
        .uli_payloads = parser.uli_payloads.items,
        .stack = try std.ArrayList(OpenNode).initCapacity(allocator, 5),
        .properties = .{ .title = "Some dummy title" },
    };

    try render.render(writer);

    try writer.flush();
}
