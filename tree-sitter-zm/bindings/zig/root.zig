extern fn tree_sitter_zm() callconv(.c) *const anyopaque;

pub fn language() *const anyopaque {
    return tree_sitter_zm();
}
