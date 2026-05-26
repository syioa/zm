const std = @import("std");

pub const NodeTag = enum {
    document,
    heading,
    paragraph,
    text,
    bold,
};

pub const Node = struct {
    tag: NodeTag,

    // DOD Child Tracking:
    // If a node has children, they are located in the flat array
    // starting at `first_child` and spanning `num_children` elements.
    first_child: u32 = std.math.maxInt(u32), // Sentinel value meaning "no children"
    num_children: u32 = 0,

    // Payload is an index to special properties of current Node
    payload: ?u32,

    pub const Document = void;
    pub const heading = struct {
        level: u8,
    };
    pub const paragraph = void;
    pub const text = struct {
        value: []const u8,
    };
    pub const bold = void;
};