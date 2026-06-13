const std = @import("std");
const zm = @import("../root.zig");
const Node = zm.AST.Node;
const Allocator = std.mem.Allocator;

pub const OpenNode = struct {
    idx: u32,
    subtree_end: u32,
};

pub const HTMLRenderer = struct {
    allocator: Allocator,
    nodes: []const Node,
    heading_payloads: []const Node.heading,
    text_payloads: []const Node.text,
    link_payloads: []const Node.link,
    uli_payloads: []const Node.unordered_list_item,
    
    stack: std.ArrayList(OpenNode),

    properties: struct {
        title: []const u8,
    },

    /// The owner of `writer` is required to flush it
    pub fn render(
        self: *HTMLRenderer,
        writer: *std.Io.Writer,
    ) error{WriteFailed, OutOfMemory}!void {
        if (!(self.nodes.len > 1)) return;

        for (0..self.nodes.len) |i| {
            while (self.stack.items.len != 0 and i >= self.stack.items[self.stack.items.len - 1].subtree_end) {
                try self.emitCloseTag(self.stack.pop().?.idx, writer);
            }

            try self.emitOpenTag(@intCast(i), writer);

            if (self.nodeHasChildren(@intCast(i))) |subtree_size| {
                try self.stack.append(self.*.allocator, .{ .idx = @intCast(i), .subtree_end = subtree_size });
            } else {
                try self.emitCloseTag(@intCast(i), writer);
            }
        }

        while (self.stack.items.len != 0) {
            try self.emitCloseTag(self.stack.pop().?.idx, writer);
        }
    }

    fn emitOpenTag(self: *const HTMLRenderer, i: u32, writer: *std.Io.Writer) error{WriteFailed}!void {
        switch (self.nodes[i].tag) {
            .document => {
                try writer.print(
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
            },
            .paragraph => {
                try writer.writeAll("<p>");
            },
            .text => {
                const text = self.text_payloads[self.nodes[i].payload.?].value;
                try writer.writeAll(text);
            },
            else => unreachable,
        }
    }

    fn emitCloseTag(self: *const HTMLRenderer, i: u32, writer: *std.Io.Writer) error{WriteFailed}!void {
        switch (self.nodes[i].tag) {
            .document => {
                try writer.writeAll("</body></html>");
            },
            .paragraph => {
                try writer.writeAll("</p>");
            },
            .text => {},
            else => unreachable,
        }
    }

    /// returns the index of the last descendant of the parent
    fn nodeHasChildren(self: *const HTMLRenderer, i: u32) ?u32 {
        if (self.nodes[i].first_child) |first_child| {
            return first_child + self.nodes[i].num_descendants;
        } else return null;
    }
};
