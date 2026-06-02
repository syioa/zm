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

fn printAST(nodes: []const Node, text_payload: []const Node.text, link_payload: []const Node.link) void {
    // _ = text_payload;
    // _ = link_payload;
    var id: u32 = 0;
    while (id < nodes.len) {
        if (nodes[id].tag == .link) {
            std.debug.print("Link text: {s}    Link url: {s}\n", .{
                text_payload[nodes[nodes[id].first_child.?].payload.?].value,
                link_payload[nodes[id].payload.?].url,
            });
        }

        id += 1;
    }
}

// ============================================================
// MAIN
// ============================================================

pub fn main() !void {
    const source =
        \\# Hello **World**
        \\This is a paragraph with **bold text** inside it.
        \\This is a paragraph with __italic text__ inside it.
        \\
        \\## Subheading
        \\More text.
        \\What is this - # heading?
        \\[Click here](https://google.com/)
        \\
        \\#### What if links contain ')'
        \\[C Wiki](https://en.wikipedia.org/wiki/C_\(programming_language\))
    ;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Tokenize
    var tokenizer = Tokenizer{ .input = source };
    var token_list = try std.ArrayList(Token).initCapacity(allocator, 10);
    while (tokenizer.next()) |token| {
        try token_list.append(allocator, token);
        std.debug.print("token type: {any}\ntoken slice: {s}\n\n", .{token.type, token.slice});
    }

    // Parse into DOD Flat Array
    var parser = Parser{
        .allocator = allocator,
        .tokens = token_list.items,
        .nodes = try std.ArrayList(Node).initCapacity(allocator, 10),
        .heading_payload = try std.ArrayList(Node.heading).initCapacity(allocator, 10),
        .text_payload = try std.ArrayList(Node.text).initCapacity(allocator, 10),
        .link_payload = try std.ArrayList(Node.link).initCapacity(allocator, 5),
    };

    // root_idx is just a u32 pointing to index 0
    const root_idx = try parser.parse();
    _ = root_idx;

    // We just pass the underlying slice of the ArrayList and the root index
    // printAST(parser.nodes.items, parser.text_payload.items, parser.link_payload.items);
}
