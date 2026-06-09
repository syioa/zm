const std = @import("std");
const Token = @import("tokenizer.zig").Token;
const TokenType = @import("tokenizer.zig").TokenType;
const Node = @import("AST.zig").Node;
const Allocator = std.mem.Allocator;

pub const Parser = struct {
    allocator: Allocator,
    tokens: []Token,
    // The single contiguous array backing the entire tree
    nodes: std.ArrayList(Node),
    index: usize = 0,

    heading_payloads: std.ArrayList(Node.heading),
    text_payloads: std.ArrayList(Node.text),
    link_payloads: std.ArrayList(Node.link),
    uli_payloads: std.ArrayList(Node.unordered_list_item),

    pub fn deinit(self: *Parser) void {
        self.nodes.deinit(self.*.allocator);
        self.heading_payloads.deinit(self.*.allocator);
        self.text_payloads.deinit(self.*.allocator);
        self.link_payloads.deinit(self.*.allocator);
        self.uli_payloads.deinit(self.*.allocator);
    }

    pub fn parse(self: *Parser) Allocator.Error!u32 {
        // The root node is always the first element in our flat array
        const root_idx = try self.appendNode(.{ .tag = .document, .payload = null, .parent_idx = null });

        const children_start_idx = self.nodes.items.len;

        while (self.index < self.tokens.len) {
            const token = self.tokens[self.index];
            switch (token.type) {
                .h1 => _ = try self.parseHeading(1, root_idx),
                .h2 => _ = try self.parseHeading(2, root_idx),
                .h3 => _ = try self.parseHeading(3, root_idx),
                .h4 => _ = try self.parseHeading(4, root_idx),
                .h5 => _ = try self.parseHeading(5, root_idx),
                .h6 => _ = try self.parseHeading(6, root_idx),
                .blockquote_marker => _ = try self.parseBlockquote(root_idx),

                .newline => {
                    self.index += 1;
                    _ = try self.appendNode(.{
                        .tag = .newline,
                        .payload = null,
                        .parent_idx = root_idx,
                    });
                },
                .text, .bold_marker, .italic_marker, .link_open, .link_close, .link_mid, .unordered_list_item, .indent => _ = try self.parseParagraph(root_idx),
            }
        }

        // Bind the root node's children to everything parsed after it
        self.bindChildren(root_idx, children_start_idx);

        return root_idx;
    }

    fn parseHeading(self: *Parser, level: u8, parent_idx: u32) Allocator.Error!u32 {
        self.index += 1; // Consume heading token
        const payload_idx = try self.appendHeadingPayload(.{ .level = level });
        const node_idx = try self.appendNode(.{
            .tag = .heading,
            .payload = payload_idx,
            .parent_idx = parent_idx,
        });

        const children_start_idx = self.nodes.items.len;

        while (self.index < self.tokens.len and self.tokens[self.index].type != .newline) {
            _ = try self.parseInline(node_idx);
        }
        if (self.index < self.tokens.len) self.index += 1; // Consume newline

        self.bindChildren(node_idx, children_start_idx);
        return node_idx;
    }

    fn parseBlockquote(self: *Parser, parent_idx: u32) Allocator.Error!u32 {
        self.index += 1;
        const node_idx = try self.appendNode(.{
            .tag = .blockquote,
            .payload = null,
            .parent_idx = parent_idx,
        });

        const children_start_idx = self.nodes.items.len;

        while (self.index < self.tokens.len and self.tokens[self.index].type != .newline) {
            _ = try self.parseInline(node_idx);
        }
        if (self.index < self.tokens.len) self.index += 1; // newline

        self.bindChildren(node_idx, children_start_idx);
        return node_idx;
    }

    fn parseParagraph(self: *Parser, parent_idx: u32) Allocator.Error!u32 {
        const node_idx = try self.appendNode(.{ .tag = .paragraph, .payload = null, .parent_idx = parent_idx });

        const children_start_idx = self.nodes.items.len;

        outer: while (self.index < self.tokens.len) {
            const t = self.tokens[self.index];
            switch (t.type) {
                .h1, .h2, .h3, .h4, .h5, .h6, .blockquote_marker => break :outer,
                .newline => {
                    if (self.index + 1 >= self.tokens.len) break :outer;
                    if (self.tokens[self.index + 1].type == .newline) break :outer;
                },
                .bold_marker,
                .italic_marker,
                .text,
                .link_open,
                .link_close,
                .link_mid,
                .unordered_list_item,
                .indent,
                => {},
            }
            _ = try self.parseInline(node_idx);
        }

        if (self.index < self.tokens.len and
            self.tokens[self.index].type == .newline)
        {
            self.index += 1;
            if (self.index < self.tokens.len and
                self.tokens[self.index].type == .newline) self.index += 1;
        }

        self.bindChildren(node_idx, children_start_idx);
        return node_idx;
    }

    fn parseInline(self: *Parser, parent_idx: u32) Allocator.Error!u32 {
        const token = self.tokens[self.index];
        switch (token.type) {
            .newline => {
                self.index += 1;
                return self.appendNode(.{
                    .tag = .newline,
                    .payload = null,
                    .parent_idx = parent_idx,
                });
            },
            .unordered_list_item, .indent => {
                return self.parseULItem(parent_idx);
            },
            .text => {
                self.index += 1;
                const payload_idx = try self.appendTextPayload(.{ .value = token.slice });
                return self.appendNode(.{ .tag = .text, .payload = payload_idx, .parent_idx = parent_idx });
            },
            .bold_marker => {
                self.index += 1; // Consume opening '*'
                const node_idx = try self.appendNode(.{
                    .tag = .bold,
                    .payload = null,
                    .parent_idx = parent_idx,
                });

                const children_start_idx = self.nodes.items.len;

                while (self.index < self.tokens.len and self.tokens[self.index].type != .bold_marker) {
                    _ = try self.parseInline(node_idx);
                }

                if (self.index < self.tokens.len and self.tokens[self.index].type == .bold_marker) {
                    self.index += 1; // Consume closing '*'
                }

                self.bindChildren(node_idx, children_start_idx);
                return node_idx;
            },
            .italic_marker => {
                self.index += 1; // consume opening '_'
                const node_idx = try self.appendNode(.{ .tag = .italic, .payload = null, .parent_idx = parent_idx });

                const children_start_idx = self.nodes.items.len;

                while (self.index < self.tokens.len and self.tokens[self.index].type != .italic_marker) {
                    _ = try self.parseInline(node_idx);
                }

                if (self.index < self.tokens.len and self.tokens[self.index].type == .italic_marker) {
                    self.index += 1; // consume closing '_'
                }

                self.bindChildren(node_idx, children_start_idx);
                return node_idx;
            },
            .link_open => {
                if (self.isLinkValid()) {
                    return self.parseLink(parent_idx);
                } else {
                    self.index += 1;
                    return self.appendNode(.{
                        .tag = .text,
                        .payload = try self.appendTextPayload(.{ .value = token.slice }),
                        .parent_idx = parent_idx,
                    });
                }
            },
            else => {
                self.index += 1;
                const payload_idx = try self.appendTextPayload(.{ .value = token.slice });
                return self.appendNode(.{
                    .tag = .text,
                    .payload = payload_idx,
                    .parent_idx = parent_idx,
                });
            },
        }
    }

    fn parseLink(self: *Parser, parent_idx: u32) Allocator.Error!u32 {
        self.index += 1; // consume .link_open

        const link_idx = try self.appendNode(.{
            .tag = .link,
            .payload = try self.appendLinkPayload(.{ .url = "" }),
            .parent_idx = parent_idx,
        });

        const children_start_idx: u32 = @intCast(self.nodes.items.len);

        _ = try self.appendNode(.{
            .tag = .text,
            .payload = try self.appendTextPayload(.{ .value = self.tokens[self.index].slice }),
            .parent_idx = link_idx,
        });
        self.index += 2; // consume .text(label) and .link_mid

        self.bindChildren(link_idx, children_start_idx);
        self.link_payloads.items[self.nodes.items[link_idx].payload.?].url = self.tokens[self.index].slice;

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

    fn parseULItem(self: *Parser, parent_idx: u32) Allocator.Error!u32 {
        var depth: u16 = 0;
        while (self.tokens[self.index].type == .indent) {
            self.index += 1;
            depth += 1;
        }

        if (self.tokens[self.index].type != .unordered_list_item) {
            if (depth != 0) self.index -= depth;

            return self.appendNode(.{
                .tag = .text,
                .payload = try self.appendTextPayload(.{ .value = self.tokens[self.index].slice }),
                .parent_idx = parent_idx,
            });
        }

        var previous_token_type: TokenType = .newline;
        if (self.index != 0) {
            previous_token_type = self.tokens[self.index - 1].type;
        }

        switch (previous_token_type) {
            .newline, .indent, .blockquote_marker => {
                self.index += 1;
                const node_idx = try self.appendNode(.{
                    .tag = .unordered_list_item,
                    .payload = try self.appendULIPayload(.{ .depth = depth }),
                    .parent_idx = parent_idx,
                });

                const children_start_idx = self.nodes.items.len;

                outer: while (self.index < self.tokens.len) {
                    switch (self.tokens[self.index].type) {
                        .newline => {
                            if (self.index + 1 >= self.tokens.len) break :outer;
                            if (self.tokens[self.index + 1].type == .newline) break :outer;
                        },
                        .blockquote_marker => break :outer,
                        else => {},
                    }
                    _ = try self.parseInline(node_idx);
                }
                if (self.index < self.tokens.len and
                    self.tokens[self.index].type == .newline)
                {
                    self.index += 1;
                    if (self.index < self.tokens.len and
                        self.tokens[self.index].type == .newline) self.index += 1;
                }

                self.bindChildren(node_idx, children_start_idx);
                return node_idx;
            },
            else => {
                return self.appendNode(.{ .tag = .text, .payload = try self.appendTextPayload(.{ .value = "- " }) });
            },
        }
    }

    // --- DOD Helper Methods ---

    /// Appends a node to the `nodes` ArrayList and returns its index
    ///
    /// This functions allocates memory if necessary
    fn appendNode(self: *Parser, node: Node) Allocator.Error!u32 {
        const idx: u32 = @intCast(self.nodes.items.len);
        try self.nodes.append(self.*.allocator, node);
        return idx;
    }

    /// Appends a heading payload and returns its index
    ///
    /// This function allocates memory if necessary
    fn appendHeadingPayload(self: *Parser, payload: Node.heading) Allocator.Error!u32 {
        const idx: u32 = @intCast(self.heading_payloads.items.len);
        try self.heading_payloads.append(self.*.allocator, payload);
        return idx;
    }

    /// Appends a text payload and returns its index
    ///
    /// This function allocates memory if necessary
    fn appendTextPayload(self: *Parser, payload: Node.text) Allocator.Error!u32 {
        const idx: u32 = @intCast(self.text_payloads.items.len);
        try self.text_payloads.append(self.*.allocator, payload);
        return idx;
    }

    /// Appends a link payload and returns its index
    ///
    /// This function allocates memory if necessary
    fn appendLinkPayload(self: *Parser, payload: Node.link) Allocator.Error!u32 {
        const idx: u32 = @intCast(self.link_payloads.items.len);
        try self.link_payloads.append(self.*.allocator, payload);
        return idx;
    }

    /// Appends an unordered list item payload and returns its index
    ///
    /// This function allocates memory if necessary
    fn appendULIPayload(self: *Parser, payload: Node.unordered_list_item) Allocator.Error!u32 {
        const idx: u32 = @intCast(self.uli_payloads.items.len);
        try self.uli_payloads.append(self.*.allocator, payload);
        return idx;
    }

    /// Get the properties of the heading node whose index is `node_idx`
    pub fn getHeadingPayload(self: *Parser, node_idx: ?u32) error{
        IndexOutOfBounds,
        HeadingTagMismatch,
        IndexFoundNull,
    }!Node.heading {
        if (node_idx) |idx| {
            if (idx >= self.nodes.items.len) return error.IndexOutOfBounds;
            if (self.nodes.items[idx].tag != .heading) return error.HeadingTagMismatch;

            if (self.nodes.items[idx].payload) |payload| {
                return self.heading_payloads.items[payload];
            } else unreachable;
        } else return error.IndexFoundNull;
    }

    /// Get the properties of the text node whose index is `node_idx`
    pub fn getTextPayload(self: *Parser, node_idx: ?u32) error{
        IndexOutOfBounds,
        TextTagMismatch,
        IndexFoundNull,
    }!Node.text {
        if (node_idx) |idx| {
            if (idx >= self.nodes.items.len) return error.IndexOutOfBounds;
            if (self.nodes.items[idx].tag != .text) return error.TextTagMismatch;

            if (self.nodes.items[idx].payload) |payload| {
                return self.text_payloads.items[payload];
            } else unreachable;
        } else return error.IndexFoundNull;
    }

    /// Get the properties of the link node whose index is `node_idx`
    pub fn getLinkPayload(self: *Parser, node_idx: ?u32) error{
        IndexOutOfBounds,
        LinkTagMismatch,
        IndexFoundNull,
    }!Node.link {
        if (node_idx) |idx| {
            if (idx >= self.nodes.items.len) return error.IndexOutOfBounds;
            if (self.nodes.items[idx].tag != .link) return error.LinkTagMismatch;

            if (self.nodes.items[idx].payload) |payload| {
                return self.link_payloads.items[payload];
            } else unreachable;
        } else return error.IndexFoundNull;
    }

    /// Get the properties of the unordered list item node whose index is `node_idx`
    pub fn getULIPayload(self: *Parser, node_idx: ?u32) error{
        IndexOutOfBounds,
        ULItemTagMismatch,
        IndexFoundNull,
    }!Node.unordered_list_item {
        if (node_idx) |idx| {
            if (idx >= self.nodes.items.len) return error.IndexOutOfBounds;
            if (self.nodes.items[idx].tag != .unordered_list_item) return error.ULItemTagMismatch;

            if (self.nodes.items[idx].payload) |payload| {
                return self.uli_payloads.items[payload];
            } else unreachable;
        } else return error.IndexFoundNull;
    }

    // Updates a node in-place to point to the range of nodes that represent its children
    fn bindChildren(self: *Parser, parent_idx: u32, start_idx: usize) void {
        const end_idx = self.nodes.items.len;
        if (end_idx > start_idx) {
            var parent = &self.nodes.items[parent_idx];
            parent.first_child = @intCast(start_idx);
            parent.num_descendants = @intCast(end_idx - start_idx);
        }
    }
};
