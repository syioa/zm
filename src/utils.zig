const std = @import("std");

/// writes the provided string, unescaping the contents
pub fn writeUnescaped(writer: *std.Io.Writer, escaped_str: []const u8) !void {
    var i: usize = 0;
    while (i < escaped_str.len) {
        if (escaped_str[i] == '\\' and i + 1 < escaped_str.len) {
            // Check what follows the backslash
            // switch (escaped_str[i + 1]) {
            //     'n' =>  try writer.writeByte('\n'),
            //     't' =>  try writer.writeByte('\t'),
            //     'r' =>  try writer.writeByte('\r'),
            //     '\\' => try writer.writeByte('\\'),
            //     '\"' => try writer.writeByte('\"'),
            //     '\'' => try writer.writeByte('\''),
            //     else => {
            //         // If it's a random backslash that isn't a known escape code,
            //         // write the backslash and the next character out normally.
            //         try writer.writeByte(escaped_str[i]);
            //         try writer.writeByte(escaped_str[i + 1]);
            //     },
            // }
            try writer.writeByte(escaped_str[i+1]);
            i += 2; // Jump past both the backslash and the escape token
        } else {
            // Write normal, non-escaped characters
            try writer.writeByte(escaped_str[i]);
            i += 1;
        }
    }
}

