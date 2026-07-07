const std = @import("std");
const zm = @import("../root.zig");

pub const test_AST = @import("AST/nullability.zig");

test {
    std.testing.refAllDecls(@This());
}
