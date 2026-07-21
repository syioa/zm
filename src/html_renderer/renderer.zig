const zm = @import("../root.zig");
const std = @import("std");

const ts = zm.tree_sitter;
const ts_symbols = zm.ts_symbols;

const utils = zm.utils;

const Allocator = std.mem.Allocator;
const Error = error{ WriteFailed, OutOfMemory };

pub const OpenTag = struct {
    idx: *const anyopaque,
};

pub const ListMode = enum { ordered, unordered };

pub const HTMLRenderer = struct {
    allocator: Allocator,

    /// The owner of `writer` is required to flush it
    writer: *std.Io.Writer,

    tree: *const ts.Tree,
    ts_kinds: *const ts_symbols.Symbols,
    source: []const u8,

    stack: std.ArrayList(OpenTag),

    list_state: struct {
        numbering: std.ArrayList(u32),
        modes: std.ArrayList(ListMode),
    },

    frontmatter: []const u8,

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
                    \\</head>
                    \\<body>
                    \\<script id="frontmatter" type="application/kdl">{s}</script>
                    \\<script type="module">
                    \\import {{ parse }} from "https://esm.sh/@bgotink/kdl/json";
                    \\window.vars = parse(document.getElementById("frontmatter").textContent)
                    \\document.title = vars.title || "Title Not Provided";
                    \\</script>
                    \\
                , .{self.frontmatter});

                try self.stack.append(self.allocator, .{ .idx = node.id });
            },
            .heading => {
                if (node.child(0)) |marker| {
                    const level = marker.endByte() - marker.startByte();
                    try self.writer.print("<h{}>", .{level});
                    try self.stack.append(self.allocator, .{ .idx = node.id });
                }
            },
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
                    if (self.source[url.startByte()] != '{') {
                        try self.writer.writeAll("<a href=\"");
                        try utils.writeUnescaped(self.writer, self.source[url.startByte()..url.endByte()]);
                    } else {
                        try self.writer.writeAll("<a data-zm-href=\"");
                        try utils.writeVar(self.writer, self.source[url.startByte()..url.endByte()]);
                    }

                    try self.writer.writeAll("\">");
                    try self.stack.append(self.allocator, .{ .idx = node.id });
                }
            },
            .text => {
                try utils.writeUnescaped(self.writer, self.source[node.startByte()..node.endByte()]);
            },
            .variable => {
                try self.writer.writeAll("<zm-var path=\"");
                try utils.writeVar(self.writer, self.source[node.startByte()..node.endByte()]);
                try self.writer.writeAll("\"></zm-var>");
            },
            .newline => {
                try self.writer.writeAll("<br>");
            },
            .unordered_list => {
                try self.writer.writeAll("<ul>");
                try self.stack.append(self.allocator, .{ .idx = node.id });
            },
            .ordered_list => {
                try self.writer.writeAll("<ol>");
                try self.stack.append(self.allocator, .{ .idx = node.id });
            },
            .unordered_list_item => {
                try self.visit_unordered_list_item(node);
            },
            .ordered_list_item => {
                try self.visit_ordered_list_item(node);
            },
            .paragraph => {
                try self.writer.writeAll("<p>");
                try self.stack.append(self.allocator, .{ .idx = node.id });
            },
            .attr => {},
            .url => {},
            .heading_marker => {},
            .unknown => {},
        }
    }

    fn leave(self: *HTMLRenderer, node: *const ts.Node, kind: ts_symbols.SymbolKind) Error!void {
        if (self.stack.items.len == 0) return;

        const open_tag = self.stack.items[self.stack.items.len - 1];
        if (open_tag.idx == node.id) {
            switch (kind) {
                .document => {
                    try self.writer.writeAll(
                        \\<script type="module">
                        \\function resolve(path, obj) {
                        \\    let current = obj;
                        \\
                        \\    for (const segment of path.split('.')) {
                        \\        if (current == null) return undefined;
                        \\
                        \\        if (Array.isArray(current)) {
                        \\            const index = Number(segment);
                        \\            if (!Number.isInteger(index)) return undefined;
                        \\            current = current[index];
                        \\        } else {
                        \\            current = current[segment];
                        \\        }
                        \\    }
                        \\
                        \\    return current;
                        \\}
                        \\
                        \\function renderVariables(root = document) {
                        \\    const missing = new Set();
                        \\
                        \\    for (const el of document.querySelectorAll("zm-var")) {
                        \\        const path = el.getAttribute("path");
                        \\        const value = resolve(path, window.vars);
                        \\    
                        \\        if (value === undefined || value === null) {
                        \\            missing.add(path);
                        \\            el.replaceWith(document.createTextNode(""));
                        \\        } else {
                        \\            el.replaceWith(document.createTextNode(String(value)));
                        \\        }
                        \\    }
                        \\
                        \\    if (missing.size > 0) {
                        \\        const div = document.createElement("div");
                        \\        div.id = "zm-errors";
                        \\
                        \\        Object.assign(div.style, {
                        \\            margin: "1rem",
                        \\            padding: "1rem",
                        \\            border: "1px solid #d97706",
                        \\            borderRadius: "6px",
                        \\            background: "#fff7ed",
                        \\            color: "#7c2d12",
                        \\            fontFamily: "system-ui, sans-serif",
                        \\            fontSize: "14px",
                        \\        });
                        \\    
                        \\        div.innerHTML = `
                        \\            <strong>Undefined frontmatter variables</strong>
                        \\            <ul>
                        \\                ${[...missing].map(v => `<li>${v}</li>`).join("")}
                        \\            </ul>
                        \\        `;
                        \\
                        \\        Object.assign(div.children[0].style, {
                        \\            display: "block",
                        \\            marginBottom: "0.5rem",
                        \\        });
                        \\
                        \\        document.body.prepend(div);
                        \\    }
                        \\}
                        \\
                        \\renderVariables();
                        \\</script>
                        \\</body></html>
                    );
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
                .unordered_list => {
                    try self.writer.writeAll("</ul>");
                    _ = self.stack.pop();

                    while (self.list_state.numbering.items.len != 0 and
                        self.list_state.modes.items.len != 0)
                    {
                        _ = self.list_state.numbering.pop();
                        _ = self.list_state.modes.pop();
                    }
                },
                .ordered_list => {
                    try self.writer.writeAll("</ol>");
                    _ = self.stack.pop();

                    while (self.list_state.numbering.items.len != 0 and
                        self.list_state.modes.items.len != 0)
                    {
                        _ = self.list_state.numbering.pop();
                        _ = self.list_state.modes.pop();
                    }
                },
                .unordered_list_item => {
                    try self.writer.writeAll("</li>");
                    _ = self.stack.pop();
                },
                .ordered_list_item => {
                    try self.writer.writeAll("</li>");
                    _ = self.stack.pop();
                },
                .paragraph => {
                    try self.writer.writeAll("</p>");
                    _ = self.stack.pop();
                },
                else => {},
            }
        }
    }

    // Helper fn
    fn visit_unordered_list_item(self: *HTMLRenderer, node: *const ts.Node) Error!void {
        var current_level: u32 = 1;
        const last_level: u32 = @intCast(self.list_state.numbering.items.len);

        if (node.child(0)) |attr| {
            if (self.ts_kinds.match(attr.kindId()) == .attr)
                current_level = ((attr.endByte() - attr.startByte()) / 2) + 1;
        }

        if (last_level >= 1) {
            if (last_level == current_level) {
                self.list_state.numbering.items[self.list_state.numbering.items.len - 1] += 1;

                if (self.list_state.modes.items[self.list_state.modes.items.len - 1] == .ordered) {
                    _ = self.list_state.modes.pop();
                    try self.list_state.modes.append(self.allocator, .unordered);
                }
            } else if (last_level < current_level) {
                while (current_level > self.list_state.numbering.items.len) {
                    try self.list_state.numbering.append(self.allocator, 1);
                    try self.list_state.modes.append(self.allocator, .unordered);
                }
            } else if (last_level > current_level) {
                while (self.list_state.numbering.items.len > current_level) {
                    _ = self.list_state.numbering.pop();
                    _ = self.list_state.modes.pop();
                }

                self.list_state.numbering.items[self.list_state.numbering.items.len - 1] += 1;
                if (self.list_state.modes.items[self.list_state.modes.items.len - 1] == .ordered) {
                    _ = self.list_state.modes.pop();
                    try self.list_state.modes.append(self.allocator, .unordered);
                }
            }
        } else {
            try self.list_state.numbering.append(self.allocator, 1);
            try self.list_state.modes.append(self.allocator, .unordered);
        }

        try self.writer.print(
            "<li style=\"--level: {d};\" data-path=\"{any}\" data-modes=\"{any}\">",
            .{
                current_level - 1,
                self.list_state.numbering.items,
                self.list_state.modes.items,
            },
        );
        try self.stack.append(self.allocator, .{ .idx = node.id });
    }

    fn visit_ordered_list_item(self: *HTMLRenderer, node: *const ts.Node) Error!void {
        var current_level: u32 = 1;
        const last_level: u32 = @intCast(self.list_state.numbering.items.len);

        if (node.child(0)) |attr| {
            if (self.ts_kinds.match(attr.kindId()) == .attr)
                current_level = ((attr.endByte() - attr.startByte()) / 2) + 1;
        }

        if (last_level >= 1) {
            if (last_level == current_level) {
                self.list_state.numbering.items[self.list_state.numbering.items.len - 1] += 1;

                if (self.list_state.modes.items[self.list_state.modes.items.len - 1] == .unordered) {
                    _ = self.list_state.modes.pop();
                    try self.list_state.modes.append(self.allocator, .ordered);
                }
            } else if (last_level < current_level) {
                while (current_level > self.list_state.numbering.items.len) {
                    try self.list_state.numbering.append(self.allocator, 1);
                    try self.list_state.modes.append(self.allocator, .ordered);
                }
            } else if (last_level > current_level) {
                while (self.list_state.numbering.items.len > current_level) {
                    _ = self.list_state.numbering.pop();
                    _ = self.list_state.modes.pop();
                }

                self.list_state.numbering.items[self.list_state.numbering.items.len - 1] += 1;
                if (self.list_state.modes.items[self.list_state.modes.items.len - 1] == .unordered) {
                    _ = self.list_state.modes.pop();
                    try self.list_state.modes.append(self.allocator, .ordered);
                }
            }
        } else {
            try self.list_state.numbering.append(self.allocator, 1);
            try self.list_state.modes.append(self.allocator, .ordered);
        }

        try self.writer.print(
            "<li style=\"--level: {d};\" data-path=\"{any}\" data-modes=\"{any}\">",
            .{
                current_level - 1,
                self.list_state.numbering.items,
                self.list_state.modes.items,
            },
        );
        try self.stack.append(self.allocator, .{ .idx = node.id });
    }
};
