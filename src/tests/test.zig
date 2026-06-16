const std = @import("std");
pub const zm = @import("../root.zig");

pub const test_AST = @import("AST/nullability.zig");

test {
    std.testing.refAllDecls(@This());
}

/// The returned value is owned by the caller and both have to be freed.
/// 
/// A arena style allocator is recommended, if ease of use is the priority.
/// 
/// If you are testing then `std.testing.allocator` is recommended
/// and you are required to free the allocated resources.
pub fn genAST(allocator: std.mem.Allocator, source: []const u8) !struct {
    token_list: std.ArrayList(zm.tokenizer.Token),
    parser: zm.parser.Parser,
} {
    // Tokenize
    var tokenizer = zm.tokenizer.Tokenizer{ .input = source };
    var token_list = try std.ArrayList(zm.tokenizer.Token).initCapacity(allocator, 10);

    while (tokenizer.next()) |token| {
        try token_list.append(allocator, token);
    }

    // Parser
    var parser = zm.parser.Parser{
        .allocator = allocator,
        .tokens = token_list.items,
        .nodes = try std.ArrayList(zm.AST.Node).initCapacity(allocator, 10),
        .heading_payloads = try std.ArrayList(zm.AST.Node.heading).initCapacity(allocator, 10),
        .text_payloads = try std.ArrayList(zm.AST.Node.text).initCapacity(allocator, 10),
        .link_payloads = try std.ArrayList(zm.AST.Node.link).initCapacity(allocator, 5),
        .uli_payloads = try std.ArrayList(zm.AST.Node.unordered_list_item).initCapacity(allocator, 5),
    };

    // Parse
    const root_idx = try parser.parse();
    _ = root_idx;

    return .{ .parser = parser, .token_list = token_list };
}

// Just sitting here, maybe useful someday
fn printAST(parser: *zm.parser.Parser) !void {
    const nodes = &parser.nodes.items;
    var id: u32 = 0;
    var count: u32 = 0;
    while (id < nodes.len) {
        if (nodes.*[id].tag == .link) {
            std.debug.print("Link text: {s}    Link url: {s}\n", .{
                (try parser.getTextPayload(nodes.*[id].first_child)).value,
                (try parser.getLinkPayload(id)).url,
            });
        } else if (nodes.*[id].tag == .bold) {
            std.debug.print("Bold text: {s}\n", .{(try parser.getTextPayload(nodes.*[id].first_child)).value});
        } else if (nodes.*[id].tag == .italic) {
            std.debug.print("Italic text: {s}\n", .{(try parser.getTextPayload(nodes.*[id].first_child)).value});
        } else if (nodes.*[id].tag == .blockquote) {
            std.debug.print("Blockquote's text: {s}\n", .{
                (try parser.getTextPayload(nodes.*[id].first_child)).value,
            });
        } else if (nodes.*[id].tag == .unordered_list_item) {
            std.debug.print("ULI depth: {}    ULI first child: {s}\n", .{
                (try parser.getULIPayload(id)).depth,
                (try parser.getTextPayload(nodes.*[id].first_child)).value,
            });
        } else if (nodes.*[id].tag == .paragraph) {
            count += 1;
        }

        id += 1;
    }

    std.debug.print("Number of paragraphs: {}\n", .{count});
}

