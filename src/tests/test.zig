const std = @import("std");
const zm = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}
