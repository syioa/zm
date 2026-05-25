const zm = @import("zm");

const std = @import("std");

// ============================================================
// 1. TOKENIZER (LEXER) - Unchanged, perfectly Zero-Copy
// ============================================================

pub const TokenType = enum {
    h1,
    h2,
    bold_marker,
    newline,
    text,
};

pub const Token = struct {
    type: TokenType,
    slice: []const u8,
};

pub const Tokenizer = struct {
    input: []const u8,
    index: usize = 0,

    pub fn next(self: *Tokenizer) ?Token {
        if (self.index >= self.input.len) return null;

        const start = self.index;
        const char = self.input[self.index];

        if (char == '\n') {
            self.index += 1;
            return Token{ .type = .newline, .slice = self.input[start..self.index] };
        }

        if (char == '*' and self.peek(1) == '*') {
            self.index += 2;
            return Token{ .type = .bold_marker, .slice = self.input[start..self.index] };
        }

        if (char == '#' and self.peek(1) == '#' and self.peek(2) == ' ') {
            self.index += 3;
            return Token{ .type = .h2, .slice = self.input[start..self.index] };
        }
        if (char == '#' and self.peek(1) == ' ') {
            self.index += 2;
            return Token{ .type = .h1, .slice = self.input[start..self.index] };
        }

        // Text fallback
        while (self.index < self.input.len) {
            const c = self.input[self.index];
            if (c == '\n') break;
            if (c == '*' and self.peek(1) == '*') break;
            if (c == '#' and ((self.peek(1) == ' ') or (self.peek(1) == '#' and self.peek(2) == ' '))) break;
            self.index += 1;
        }

        if (self.index == start) self.index += 1; // Prevent infinite loops

        return Token{ .type = .text, .slice = self.input[start..self.index] };
    }

    fn peek(self: *Tokenizer, offset: usize) u8 {
        const target_index = self.index + offset;
        if (target_index >= self.input.len) return 0;
        return self.input[target_index];
    }
};

// ============================================================
// 2. ABSTRACT SYNTAX TREE (DOD Flattened)
// Nodes are just data. No pointers. Children are indices.
// ============================================================

pub const NodeTag = enum {
    document,
    heading,
    paragraph,
    text,
    bold,
};

pub const Node = struct {
    tag: NodeTag,

    // DOD Child Tracking:
    // If a node has children, they are located in the flat array
    // starting at `first_child` and spanning `num_children` elements.
    first_child: u32 = std.math.maxInt(u32), // Sentinel value meaning "no children"
    num_children: u32 = 0,

    // Payload is an index to special properties of current Node
    payload: ?u32,

    const Document = void;
    const heading = struct {
        level: u8,
    };
    const paragraph = void;
    const text = struct {
        value: []const u8,
    };
    const bold = void;
};

// ============================================================
// 3. PARSER (Data-Oriented)
// Appends nodes to a flat array. Returns indices (u32) instead of pointers.
// ============================================================

pub const Parser = struct {
    allocator: std.mem.Allocator,
    tokens: []Token,
    // The single contiguous array backing the entire tree
    nodes: std.ArrayList(Node),
    index: usize = 0,

    heading_payload: std.ArrayList(Node.heading),
    text_payload: std.ArrayList(Node.text),

    pub fn parse(self: *Parser) !u32 {
        // The root node is always the first element in our flat array
        const root_idx = try self.appendNode(.{ .tag = .document, .payload = null });

        const children_start_idx = self.nodes.items.len;

        while (self.index < self.tokens.len) {
            const token = self.tokens[self.index];
            switch (token.type) {
                .h1 => _ = try self.parseHeading(1),
                .h2 => _ = try self.parseHeading(2),
                .newline => self.index += 1,
                .text, .bold_marker => _ = try self.parseParagraph(),
            }
        }

        // Bind the root node's children to everything parsed after it
        self.bindChildren(root_idx, children_start_idx);

        return root_idx;
    }

    fn parseHeading(self: *Parser, level: u8) !u32 {
        self.index += 1; // Consume heading token
        const payload_idx = try self.appendHeadingPayload(.{ .level = level });
        const node_idx = try self.appendNode(.{ .tag = .heading, .payload = payload_idx });

        const children_start_idx = self.nodes.items.len;

        while (self.index < self.tokens.len and self.tokens[self.index].type != .newline) {
            _ = try self.parseInline();
        }
        if (self.index < self.tokens.len) self.index += 1; // Consume newline

        self.bindChildren(node_idx, children_start_idx);
        return node_idx;
    }

    fn parseParagraph(self: *Parser) !u32 {
        const node_idx = try self.appendNode(.{ .tag = .paragraph, .payload = null });

        const children_start_idx = self.nodes.items.len;

        while (self.index < self.tokens.len) {
            const t = self.tokens[self.index];
            if (t.type == .newline or t.type == .h1 or t.type == .h2) break;
            _ = try self.parseInline();
        }

        if (self.index < self.tokens.len and self.tokens[self.index].type == .newline) {
            self.index += 1;
        }

        self.bindChildren(node_idx, children_start_idx);
        return node_idx;
    }

    fn parseInline(self: *Parser) !u32 {
        const token = self.tokens[self.index];
        switch (token.type) {
            .text => {
                self.index += 1;
                const payload_idx = try self.appendTextPayload(.{ .value = token.slice });
                return self.appendNode(.{ .tag = .text, .payload = payload_idx });
            },
            .bold_marker => {
                self.index += 1; // Consume opening '**'
                const node_idx = try self.appendNode(.{ .tag = .bold, .payload = null });

                const children_start_idx = self.nodes.items.len;

                while (self.index < self.tokens.len and self.tokens[self.index].type != .bold_marker) {
                    _ = try self.parseInline();
                }

                if (self.index < self.tokens.len and self.tokens[self.index].type == .bold_marker) {
                    self.index += 1; // Consume closing '**'
                }

                self.bindChildren(node_idx, children_start_idx);
                return node_idx;
            },
            else => unreachable,
        }
    }

    // --- DOD Helper Methods ---

    // Appends a node to the contiguous array and returns its index
    fn appendNode(self: *Parser, node: Node) !u32 {
        const idx: u32 = @intCast(self.nodes.items.len);
        try self.nodes.append(self.*.allocator, node);
        return idx;
    }

    fn appendHeadingPayload(self: *Parser, payload: Node.heading) !u32 {
        const idx: u32 = @intCast(self.heading_payload.items.len);
        try self.heading_payload.append(self.*.allocator, payload);
        return idx;
    }

    fn appendTextPayload(self: *Parser, payload: Node.text) !u32 {
        const idx: u32 = @intCast(self.text_payload.items.len);
        try self.text_payload.append(self.*.allocator, payload);
        return idx;
    }

    // Updates a node in-place to point to the range of nodes that represent its children
    fn bindChildren(self: *Parser, parent_idx: u32, start_idx: usize) void {
        const end_idx = self.nodes.items.len;
        if (end_idx > start_idx) {
            var parent = &self.nodes.items[parent_idx];
            parent.first_child = @intCast(start_idx);
            parent.num_children = @intCast(end_idx - start_idx);
        }
    }
};

// ============================================================
// 4. AST PRINTER (DOD Traversal)
// Traverses using simple array indexing instead of pointer dereferencing.
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
