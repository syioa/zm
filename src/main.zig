const std = @import("std");
const zm = @import("zm");

const Token = zm.tokenizer.Token;
const TokenType = zm.tokenizer.TokenType;
const Tokenizer = zm.tokenizer.Tokenizer;

const Node = zm.AST.Node;

const Parser = zm.parser.Parser;



// ============================================================
// 4. AST PRINTER
// ============================================================

fn printAST(nodes: []const Node, text_payload: []const Node.text) void {
    var id: u32 = 0;
    while (id < nodes.len) {
        if (nodes[id].tag == .heading) {
            std.debug.print("Node id: {}\n    {s}\n", .{ id, text_payload[nodes[nodes[id].first_child].payload.?].value });
        }
        id += 1;
    }
}

// ============================================================
// 5. MAIN
// ============================================================

pub fn main() !void {
    const source =
        \\# Hello World
        \\This is a paragraph with **bold text** inside it.
        \\
        \\## Subheading
        \\More text.
    ;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // 1. Tokenize
    var tokenizer = Tokenizer{ .input = source };
    var token_list = try std.ArrayList(Token).initCapacity(allocator, 10);
    while (tokenizer.next()) |token| {
        try token_list.append(allocator, token);
    }

    // 2. Parse into DOD Flat Array
    var parser = Parser{
        .allocator = allocator,
        .tokens = token_list.items,
        .nodes = try std.ArrayList(Node).initCapacity(allocator, 10),
        .heading_payload = try std.ArrayList(Node.heading).initCapacity(allocator, 10),
        .text_payload = try std.ArrayList(Node.text).initCapacity(allocator, 10),
    };

    // root_idx is just a u32 pointing to index 0
    const root_idx = try parser.parse();
    _ = root_idx;

    // 3. Print via DOD Traversal
    // We just pass the underlying slice of the ArrayList and the root index
    printAST(parser.nodes.items, parser.text_payload.items);
}
