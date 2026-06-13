pub const NodeTag = enum {
    document,
    heading,
    paragraph,
    text,
    newline,
    bold,
    italic,
    link,
    blockquote,
    unordered_list_item,
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

    // Properties of All Node types
    pub const document = void;
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
    pub const blockquote = void;
    // pub const newline = void;
    pub const unordered_list_item = struct {
        depth: u16,
    };
};
