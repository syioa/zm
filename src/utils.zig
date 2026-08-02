const std = @import("std");
const zm = @import("root.zig");
const kdl = zm.kdl;
const ts = zm.tree_sitter;

/// writes the provided string, unescaping the contents
pub fn writeUnescaped(writer: *std.Io.Writer, escaped_str: []const u8) !void {
    var i: usize = 0;
    while (i < escaped_str.len) {
        if (escaped_str[i] == '\\' and i + 1 < escaped_str.len) {
            try writer.writeByte(escaped_str[i + 1]);
            i += 2;
        } else {
            // Write normal, non-escaped characters
            try writer.writeByte(escaped_str[i]);
            i += 1;
        }
    }
}

pub fn writeVar(writer: *std.Io.Writer, str: []const u8) !void {
    try writer.writeAll(
        std.mem.trim(u8, str[1..(str.len - 1)], " \t\r\n"),
    );
}

/// return the index from where the content starts, excluding
/// the frontmatter marker.
///
/// returns 0 if no frontmatter present and an error if
/// unclosed frontmatter found.
pub fn splitFrontmatter(source: []const u8) !usize {
    if (!std.mem.startsWith(u8, source, "---\n"))
        return 0;

    var pos: usize = 4;

    while (std.mem.findScalarPos(u8, source, pos, '\n')) |nl| {
        const j = nl + 1;

        if (j + 4 <= source.len and
            source[j] == '-' and
            source[j + 1] == '-' and
            source[j + 2] == '-' and
            source[j + 3] == '\n')
        {
            return j + 4;
        }

        pos = j;
    }

    return error.UnclosedDelimiter;
}

pub fn findErrorsPos(root: *const ts.Node) void {
    if (!root.hasError()) return;

    var cursor = root.walk();
    defer cursor.destroy();

    while (true) {
        const node = cursor.node();

        if (node.isError() or node.isMissing()) {
            const start = node.startPoint();
            std.log.warn(
                "Syntax error at line {d}, column {d}",
                .{ start.row + 1, start.column + 1 },
            );
        }

        // Only descend into children if this subtree actually has an error
        if (node.hasError() and cursor.gotoFirstChild()) {
            continue;
        }

        // No children (or no error below) -> move to next sibling,
        // walking back up until we find one or exit the tree
        while (!cursor.gotoNextSibling()) {
            if (!cursor.gotoParent()) return; // back at root, done
        }
    }
}

/// Returns true if `input` is syntactically valid KDL.
pub fn isValidKdl(gpa: std.mem.Allocator, input: []const u8) !bool {
    if (input.len == 0) return true;
    const source = try gpa.dupeSentinel(u8, input, 0);
    defer gpa.free(source);

    var parser = kdl.Parser.init(source);

    var depth: usize = 0;
    var event = try parser.next();
    while (event != .eof) : (event = try parser.next()) {
        switch (event) {
            .invalid => return false, // explicit syntax error
            .child_block_begin => depth += 1,
            .child_block_end => {
                if (depth == 0) return false; // stray `}`
                depth -= 1;
            },
            else => {},
        }
    }

    return depth == 0; // catches an unclosed `{`
}

test "valid kdl" {
    const gpa = std.testing.allocator;
    try std.testing.expect(try isValidKdl(gpa,
        \\addr "127.0.0.1:4000"
        \\tmp-path "dev-local-files/tmp"
    ));
}

test "invalid kdl - unbalanced brace" {
    const gpa = std.testing.allocator;
    try std.testing.expect(!try isValidKdl(gpa,
        \\node {
        \\  child
    ));
}
