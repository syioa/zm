const std = @import("std");
const zm = @import("../root.zig");

const Parser = zm.parser.Parser;

fn printAST(parser: *Parser) !void {
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

