const std = @import("std");

pub const NodeTag = enum {
    document,
    heading,
    paragraph,
    text,
    bold,
    italic,
    link,
};

pub const Node = struct {
    tag: NodeTag,

    /// If a node has children, they are located in the flat array
    /// starting at `first_child` and spanning `num_descendants` elements.
    first_child: ?u32 = null,
    num_descendants: u32 = 0,
    parent_idx: ?u32 = null,

    /// Payload is an index to special properties of current Node
    payload: ?u32,

    pub const Document = void;
    pub const heading = struct {
        level: u8,
    };
    pub const paragraph = void;
    pub const text = struct {
        value: []const u8,
    };
    pub const link = struct {
        url: []const u8,
    };
    pub const bold = void;
};
