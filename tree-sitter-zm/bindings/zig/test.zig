const testing = @import("std").testing;

const ts = @import("tree_sitter");
const root = @import("tree-sitter-zm");
const Language = ts.Language;
const Parser = ts.Parser;

test "can load grammar" {
    const parser = Parser.create();
    defer parser.destroy();

    const lang: *const ts.Language = Language.fromRaw(root.language());
    defer lang.destroy();

    try testing.expectEqual(void{}, parser.setLanguage(lang));
    try testing.expectEqual(lang, parser.getLanguage());
}

test "parse a string" {
    const parser = Parser.create();
    defer parser.destroy();

    const lang: *const ts.Language = Language.fromRaw(root.language());
    defer lang.destroy();

    try parser.setLanguage(lang);

    const source_file = "# Hello World";
    const tree = parser.parseString(source_file, null) orelse {
        return error.TestFail;
    };
    defer tree.destroy();
}