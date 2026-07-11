const std = @import("std");
const zm = @import("root.zig");
const ts = zm.tree_sitter;
const ts_zm = zm.tree_sitter_zm;

pub const SymbolKind = enum {
    document,
    heading,
    heading_marker,
    bold,
    italic,
    text,
    attr,
    url,
    newline,
    link,
    unordered_list,
    unordered_list_item,

    unknown,
};

pub const Symbols = struct {
    document: u16,

    heading: u16,
    heading_marker: u16,

    bold: u16,
    italic: u16,

    text: u16,
    attr: u16,
    url: u16,

    newline: u16,

    link: u16,

    unordered_list: u16,
    unordered_list_item: u16,

    pub fn init(lang: *const ts.Language) Symbols {
        return .{
            .document = lang.idForNodeKind("document", true),

            .heading = lang.idForNodeKind("heading", true),
            .heading_marker = lang.idForNodeKind("heading_marker", true),

            .bold = lang.idForNodeKind("bold", true),
            .italic = lang.idForNodeKind("italic", true),

            .text = lang.idForNodeKind("text", true),
            .attr = lang.idForNodeKind("attr", true),
            .url = lang.idForNodeKind("url", true),

            .newline = lang.idForNodeKind("newline", true),

            .link = lang.idForNodeKind("link", true),

            .unordered_list = lang.idForNodeKind("unordered_list", true),
            .unordered_list_item = lang.idForNodeKind("unordered_list_item", true),
        };
    }

    pub fn match(self: *const Symbols, variant: u16) SymbolKind {
        if (variant == self.document) {
            return .document;
        } else if (variant == self.heading) {
            return .heading;
        } else if (variant == self.heading_marker) {
            return .heading_marker;
        } else if (variant == self.bold) {
            return .bold;
        } else if (variant == self.italic) {
            return .italic;
        } else if (variant == self.text) {
            return .text;
        } else if (variant == self.attr) {
            return .attr;
        } else if (variant == self.url) {
            return .url;
        } else if (variant == self.newline) {
            return .newline;
        } else if (variant == self.link) {
            return .link;
        } else if (variant == self.unordered_list) {
            return .unordered_list;
        } else if (variant == self.unordered_list_item) {
            return .unordered_list_item;
        } else {
            return .unknown;
        }
    }
};
