const std = @import("std");
const utils = @import("../test.zig");
const allocator = std.testing.allocator;

//TODO: Test data is to be expanded in all of the following test cases

test "text properties" {
    var data = try utils.genAST(allocator,
        \\Hello World
    );
    defer data.token_list.deinit(allocator);
    defer data.parser.deinit();
    
    for (data.parser.nodes.items) |node| {
        if (node.tag == .text) {
            // text payloads should never be null
            try std.testing.expect(node.payload != null);
            // text nodes should not have any children
            try std.testing.expect(node.first_child == null);
            try std.testing.expect(node.num_descendants == 0);
        }
    }
}

test "heading properties" {
    var data = try utils.genAST(allocator,
        \\# Hello World
        \\## Hello Zig
        \\### Hi
        \\#### Hola
        \\##### Hi Nan
        \\###### Hello End
    );
    defer data.token_list.deinit(allocator);
    defer data.parser.deinit();
    
    for (data.parser.nodes.items) |node| {
        if (node.tag == .heading) {
            // heading payloads should never be null
            try std.testing.expect(node.payload != null);
        }
    }
}


test "link properties" {
    var data = try utils.genAST(allocator,
        \\[hello](https://somellink.com)
        \\[link with no url]()
        \\[](https://link-with-only-url.com)
    );
    defer data.token_list.deinit(allocator);
    defer data.parser.deinit();
    
    for (data.parser.nodes.items) |node| {
        if (node.tag == .link) {
            // link payloads should never be null
            try std.testing.expect(node.payload != null);
            // a link must have a first child as a text node
            try std.testing.expect(node.first_child != null);
            try std.testing.expect(
                data.parser.nodes.items[node.first_child.?].tag == .text,
            );
        }
    }
}

test "uli(unordered list item) properties" {
    var data = try utils.genAST(allocator,
        \\- hello 1
        \\
        \\    - hello 1.1
        \\
        \\- hello 2
        \\
        \\    - hello 2.1
        \\
        \\    - hello 2.2
        \\
        \\- hello 3
        \\
    );
    defer data.token_list.deinit(allocator);
    defer data.parser.deinit();
    
    for (data.parser.nodes.items) |node| {
        if (node.tag == .unordered_list_item) {
            // uli payloads should never be null
            try std.testing.expect(node.payload != null);
        }
    }
}

