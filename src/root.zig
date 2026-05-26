const std = @import("std");
pub const tokenizer = @import("zm/tokenizer.zig");
pub const AST = @import("zm/AST.zig");
pub const parser = @import("zm/parser.zig");

pub fn repeat(allocator: std.mem.Allocator, pattern: []const u8, count: usize) ![]u8 {
    const result = try allocator.alloc(u8, pattern.len * count);
    errdefer allocator.free(result);

    var i: usize = 0;
    while (i < count) : (i += 1) {
        @memcpy(result[i * pattern.len ..][0..pattern.len], pattern);
    }
    return result;
}
