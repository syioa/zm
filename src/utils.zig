const std = @import("std");

/// writes the provided string, unescaping the contents
pub fn writeUnescaped(writer: *std.Io.Writer, escaped_str: []const u8) !void {
    var i: usize = 0;
    while (i < escaped_str.len) {
        if (escaped_str[i] == '\\' and i + 1 < escaped_str.len) {
            try writer.writeByte(escaped_str[i+1]);
            i += 2;
        } else {
            // Write normal, non-escaped characters
            try writer.writeByte(escaped_str[i]);
            i += 1;
        }
    }
}

