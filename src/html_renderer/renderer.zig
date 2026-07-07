const zm = @import("../root.zig");
const std = @import("std");

const ts = zm.tree_sitter;
const ts_symbols = zm.ts_symbols;

const Allocator = std.mem.Allocator;
const Error = error{ WriteFailed, OutOfMemory };

pub const OpenTag = struct {
    idx: *const anyopaque,
};

pub const HTMLRenderer = struct {
    allocator: Allocator,

    /// The owner of `writer` is required to flush it
    writer: *std.Io.Writer,

    tree: *const ts.Tree,
    ts_kinds: *const ts_symbols.Symbols,
    source: []const u8,

    stack: std.ArrayList(OpenTag),

    properties: struct {
        title: []const u8,
    },

    pub fn render(self: *HTMLRenderer) Error!void {
        var cursor = self.tree.walk();
        defer cursor.destroy();

        var depth: usize = 0;

        while (true) {
            const node = cursor.node();
            const kind = self.ts_kinds.match(node.kindId());

            try self.visit(&node, kind);

            // STEPPING ENGINE
            if (cursor.gotoFirstChild()) {
                depth += 1;
                continue;
            }

            try self.leave(&node, kind);

            if (cursor.gotoNextSibling()) {
                continue;
            }

            // retract upwards
            var found_sibling = false;
            while (depth > 0) {
                _ = cursor.gotoParent();
                depth -= 1;

                const parent_node = cursor.node();
                const parent_kind = self.ts_kinds.match(parent_node.kindId());
                try self.leave(&parent_node, parent_kind);

                if (cursor.gotoNextSibling()) {
                    found_sibling = true;
                    break;
                }
            }

            if (!found_sibling) break; // no sibling then break
        }
    }

    fn visit(
        self: *HTMLRenderer,
        node: *const ts.Node,
        kind: ts_symbols.SymbolKind,
    ) Error!void {
        switch (kind) {
            .document => {
                try self.writer.print(
                    \\<!doctype html>
                    \\<html lang="en">
                    \\<head>
                    \\    <meta charset="UTF-8">
                    \\    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    \\    <title>{s}</title>
                    \\</head>
                    \\<body>
                    \\
                , .{self.properties.title});

                try self.stack.append(self.allocator, .{ .idx = node.id });
            },
            .heading => {
                if (node.child(0)) |marker| {
                    const level = marker.endByte() - marker.startByte();
                    try self.writer.print("<h{}>", .{level});
                    try self.stack.append(self.allocator, .{ .idx = node.id });
                }
            },
            .heading_marker => {},
            .bold => {
                try self.writer.writeAll("<strong>");
                try self.stack.append(self.allocator, .{ .idx = node.id });
            },
            .italic => {
                try self.writer.writeAll("<em>");
                try self.stack.append(self.allocator, .{ .idx = node.id });
            },
            .link => {
                if (node.namedChild(1)) |url| {
                    try self.writer.print(
                        "<a href=\"{s}\">",
                        .{self.source[url.startByte()..url.endByte()]},
                    );
                    try self.stack.append(self.allocator, .{ .idx = node.id });
                }
            },
            .text => {
                try self.writer.writeAll(self.source[node.startByte()..node.endByte()]);
            },
            .newline => {
                try self.writer.writeAll("<br>");
            },
            .url => {},
            .unknown => {},
        }
    }

    fn leave(self: *HTMLRenderer, node: *const ts.Node, kind: ts_symbols.SymbolKind) Error!void {
        if (self.stack.items.len == 0) return;

        const open_tag = self.stack.items[self.stack.items.len - 1];
        if (open_tag.idx == (node.id)) {
            switch (kind) {
                .document => {
                    try self.writer.writeAll("</body></html>");
                    _ = self.stack.pop();
                },
                .heading => {
                    if (node.child(0)) |marker| {
                        const level = marker.endByte() - marker.startByte();

                        try self.writer.print("</h{}>", .{level});
                        _ = self.stack.pop();
                    }
                },
                .bold => {
                    try self.writer.writeAll("</strong>");
                    _ = self.stack.pop();
                },
                .italic => {
                    try self.writer.writeAll("</em>");
                    _ = self.stack.pop();
                },
                .link => {
                    try self.writer.writeAll("</a>");
                    _ = self.stack.pop();
                },
                .text => {},
                .newline => {},
                else => {},
            }
        }
    }
};
