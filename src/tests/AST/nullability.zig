const std = @import("std");
const utils = @import("../test.zig");
const allocator = std.testing.allocator;

test "text properties" {
    var data = try utils.genAST(allocator,
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Phasellus tempor feugiat lacus tincidunt porttitor. Nullam
        \\hendrerit dui vulputate, varius nibh eu, bibendum diam. Proin at
        \\nisi sapien. Aenean fermentum eros at congue dictum. Sed congue
        \\felis tempus, malesuada massa sit amet, tempus nisl. Proin a neque
        \\sit amet urna suscipit elementum eget quis diam. Nam in tellus mollis,
        \\fermentum enim volutpat, faucibus elit. Nam eget pulvinar nunc. Suspendisse
        \\potenti. Aliquam luctus massa at massa cursus dapibus. Pellentesque
        \\dignissim ante laoreet massa sagittis, a venenatis odio interdum.
        \\Phasellus et tempus diam. Duis nulla quam, dapibus non dignissim et, viverra at elit.
        \\
        \\Morbi interdum mauris velit, at pretium dui ultrices nec.
        \\Nullam lacus leo, lobortis at tempus ac, congue nec nisi.
        \\Fusce fermentum libero ac mi sollicitudin, nec bibendum
        \\erat porta. Praesent egestas magna urna, vel placerat
        \\justo rutrum at. Nulla orci libero, iaculis eu diam
        \\pulvinar, pretium placerat dolor. Duis sit amet lobortis
        \\ipsum. Proin eu enim iaculis, blandit elit bibendum,
        \\mattis est. Praesent at pellentesque sem, et varius odio.
        \\Nulla fringilla vel libero non pharetra.
        \\
        \\Fusce pulvinar nunc lorem, ut bibendum sapien tincidunt quis.
        \\Maecenas augue nunc, vestibulum at nibh sed, feugiat semper dui.
        \\Cras suscipit velit nec augue ullamcorper vestibulum. Quisque
        \\maximus, orci in laoreet pellentesque, leo neque ornare nisi,
        \\sed pulvinar erat elit nec leo. Cras auctor lectus vitae tristique
        \\iaculis. Sed velit leo, pharetra lacinia ante id, suscipit viverra
        \\est. Nam mi libero, volutpat at turpis a, hendrerit venenatis risus.
        \\Fusce tristique quis ex ut egestas. Vivamus posuere lorem a est dictum,
        \\sit amet venenatis metus efficitur.
        \\
        \\Etiam maximus posuere egestas. Quisque commodo efficitur faucibus.
        \\Fusce ac nunc lobortis, posuere nulla id, finibus est. Donec et lectus
        \\odio. Morbi molestie sit amet nibh eget faucibus. Vivamus eget diam lacus.
        \\Nam condimentum risus vitae nisi pulvinar consectetur.
        \\
        \\Nulla consequat ultricies consectetur. Pellentesque faucibus
        \\dignissim scelerisque. Pellentesque ultricies scelerisque malesuada.
        \\Morbi porta ligula quis leo scelerisque, volutpat volutpat augue
        \\scelerisque. Donec nec laoreet nulla, eu sodales tellus. Fusce
        \\fermentum neque in pulvinar pretium. Sed egestas, elit ac interdum
        \\lacinia, est nisi tincidunt dolor, a auctor nulla eros eu nunc.
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

            // text payload idx is not out of bounds of `text_payloads` ArrayList
            try std.testing.expect(node.payload.? < data.parser.text_payloads.items.len);
        }
    }
}

test "heading properties" {
    var data = try utils.genAST(allocator,
        \\# Main Heading
        \\## Heading with *bold text*
        \\### Heading with _italic text_
        \\#### ---------------------
        \\##### [[[[[[[[[[]]]]]]]]]]
        \\###### *******************
        \\######## Weird Heading Level
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
        \\[hello[]]
        \\[]()
        \\[link with no url]()
        \\[](https://link-with-only-url.com)
        \\[weird link](https://user:pa%40ss@[2001:db8::1]:8080/a/b/../c//d?x=1&x=2&y=%F0%9F%98%80#frag)
        \\[a [nested] link](https://example.com)
        \\[[[deeply nested]]](https://example.com)
        \\[text [with [multiple] levels]](https://example.com)
        \\[link](https://example.com/foo(bar\))
        \\[link](https://example.com/foo(bar(baz\)\))
        \\*[bold link](https://google.com/)*
        \\_[italic link](https://google.com/)_
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
        \\- list item 1
        \\
        \\- list item 2
        \\
        \\- list item 3
        \\
        \\- item 4
        \\
        \\        - item 4.1.1
        \\
        \\    - item 4.2
        \\
        \\- item 5
        \\
        \\    - item 5.1
        \\
        \\    - item 5.2
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

