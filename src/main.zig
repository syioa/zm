const std = @import("std");
const zm = @import("zm");

const Token = zm.tokenizer.Token;
const TokenType = zm.tokenizer.TokenType;
const Tokenizer = zm.tokenizer.Tokenizer;
const Node = zm.AST.Node;
const Parser = zm.parser.Parser;

// ============================================================
// AST PRINTER
// ============================================================

fn printAST(parser: *Parser) !void {
    const nodes = &parser.nodes.items;
    var id: u32 = 0;
    var count: u32 = 0;
    while (id < nodes.len) {
        if (nodes.*[id].tag == .link) {
            std.debug.print("Link text: {s}    Link url: {s}\n", .{
                (try parser.getTextPayload(nodes.*[id].first_child)).value,
                (try parser.getLinkPayload(id)).url,
            });
        } else if (nodes.*[id].tag == .bold) {
            std.debug.print("Bold text: {s}\n", .{(try parser.getTextPayload(nodes.*[id].first_child)).value});
        } else if (nodes.*[id].tag == .italic) {
            std.debug.print("Italic text: {s}\n", .{(try parser.getTextPayload(nodes.*[id].first_child)).value});
        } else if (nodes.*[id].tag == .paragraph) {
            count += 1;
        }

        id += 1;
    }

    std.debug.print("Number of paragraphs: {}\n", .{count});
}

// ============================================================
// MAIN
// ============================================================

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();
    const allocator = arena.allocator();
    // const allocator = init.gpa;

    const source = try std.Io.Dir.cwd().readFileAlloc(init.io, "./tests/main.md", init.gpa, .limited(1024 * 20));
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
    };
    defer parser.deinit();

    // root_idx is just a u32 pointing to index 0
    const root_idx = try parser.parse();
    _ = root_idx;

    // We just pass the underlying slice of the ArrayList and the root index
    try printAST(&parser);
}
