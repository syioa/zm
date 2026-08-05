const std = @import("std");
const zm = @import("root.zig");
const ts = zm.tree_sitter;

pub fn findFirstError(root: *const ts.Node) ?ts.Node {
    var cursor = root.walk();
    defer cursor.destroy();

    while (true) {
        const node = cursor.node();

        if (node.isError() or node.isMissing()) {
            return node;
        }

        // Only descend into children if this subtree actually has an error
        if (node.hasError() and cursor.gotoFirstChild()) {
            continue;
        }

        // No children (or no error below) -> move to next sibling,
        // walking back up until we find one or exit the tree
        while (!cursor.gotoNextSibling()) {
            if (!cursor.gotoParent()) return null; // back at root, done
        }
    }

    return null;
}

pub fn diagnosticMessage(node: ts.Node) []const u8 {
    _ = node;
    return "syntax error";
}

pub fn getLineFromByte(source: []const u8, byte: usize) []const u8 {
    const start = std.mem.lastIndexOfScalar(u8, source[0..byte], '\n') orelse 0;
    const line_start = if (start == 0) 0 else start + 1;

    const line_end = std.mem.findScalarPos(u8, source, byte, '\n') orelse source.len;

    return source[line_start..line_end];
}

