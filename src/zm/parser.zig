const std = @import("std");
const Token = @import("./tokenizer.zig").Token;
const TokenType = @import("tokenizer.zig").TokenType;
const Node = @import("./AST.zig").Node;

pub const Parser = struct {
    allocator: std.mem.Allocator,
    tokens: []Token,
    // The single contiguous array backing the entire tree
    nodes: std.ArrayList(Node),
    index: usize = 0,

    heading_payload: std.ArrayList(Node.heading),
    text_payload: std.ArrayList(Node.text),
    link_payload: std.ArrayList(Node.link),

    pub fn parse(self: *Parser) !u32 {
        // The root node is always the first element in our flat array
        const root_idx = try self.appendNode(.{ .tag = .document, .payload = null });

        const children_start_idx = self.nodes.items.len;

        while (self.index < self.tokens.len) {
            const token = self.tokens[self.index];
            switch (token.type) {
                .h1 => _ = try self.parseHeading(1),
                .h2 => _ = try self.parseHeading(2),
                .h3 => _ = try self.parseHeading(3),
                .h4 => _ = try self.parseHeading(4),
                .h5 => _ = try self.parseHeading(5),
                .h6 => _ = try self.parseHeading(6),
                .newline => self.index += 1,
                .text, .bold_marker, .italic_marker, .link_open, .link_close, .link_mid => _ = try self.parseParagraph(),
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

        outer: while (self.index < self.tokens.len) {
            const t = self.tokens[self.index];
            switch (t.type) {
                .h1, .h2, .h3, .h4, .h5, .h6, .newline => break :outer,
                .bold_marker, .italic_marker, .text, .link_open, .link_close, .link_mid => {},
            }
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
            .italic_marker => {
                self.index += 1; // consume opening '__'
                const node_idx = try self.appendNode(.{ .tag = .italic, .payload = null });

                const children_start_idx = self.nodes.items.len;

                while (self.index < self.tokens.len and self.tokens[self.index].type != .italic_marker) {
                    _ = try self.parseInline();
                }

                if (self.index < self.tokens.len and self.tokens[self.index].type == .italic_marker) {
                    self.index += 1; // consume closing '**'
                }

                self.bindChildren(node_idx, children_start_idx);
                return node_idx;
            },
            .link_open => {
                if (self.isLinkValid()) {
                    return self.parseLink();
                } else {
                    self.index += 1;
                    return self.appendNode(.{
                        .tag = .text,
                        .payload = try self.appendTextPayload(.{ .value = token.slice }),
                    });
                }
            },
            else => {
                self.index += 1;
                const payload_idx = try self.appendTextPayload(.{ .value = token.slice });
                return self.appendNode(.{ .tag = .text, .payload = payload_idx });
            },
        }
    }

    fn parseLink(self: *Parser) !u32 {
        self.index += 1; // consume .link_open

        const link_idx = try self.appendNode(.{ .tag = .link, .payload = try self.appendLinkPayload(.{ .url = "" }) });

        const children_start_idx: u32 = @intCast(self.nodes.items.len);

        _ = try self.appendNode(.{
            .tag = .text,
            .payload = try self.appendTextPayload(.{ .value = self.tokens[self.index].slice }),
        });
        self.index += 2; // consume .text(label) and .link_mid

        self.bindChildren(link_idx, children_start_idx);
        self.link_payload.items[self.nodes.items[link_idx].payload.?].url = self.tokens[self.index].slice;

        self.index += 2; // consume .text(url) and .link_close

        return link_idx;
    }

    fn isLinkValid(self: *Parser) bool {
        if ((self.index + 4) >= self.tokens.len) return false;
        var peek_idx = self.index + 1;

        if (self.tokens[peek_idx].type != .text) return false;
        peek_idx += 1;

        if (self.tokens[peek_idx].type != .link_mid) return false;
        peek_idx += 1;

        if (self.tokens[peek_idx].type != .text) return false;
        peek_idx += 1;

        return if (self.tokens[peek_idx].type != .link_close) false else true;
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

    fn appendLinkPayload(self: *Parser, payload: Node.link) !u32 {
        const idx: u32 = @intCast(self.link_payload.items.len);
        try self.link_payload.append(self.*.allocator, payload);
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
