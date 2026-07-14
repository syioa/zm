# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

- - -
## 0.2.1 - 2026-07-14
#### Features
- implement nested ordered lists - (cba55b4) - syioa
#### Bug Fixes
- (**html-renderer**) remove all elements from the ol_numbering when ol is rendered - (43635e2) - syioa

- - -

## 0.2.0 - 2026-07-12
#### Features
- (**html-renderer**) implement rendering of bold, italic and links to html - (6ba2c4a) - syioa
- (**html-renderer**) render headings - (179ce1d) - syioa
- add nested ordered lists - (3222fa3) - syioa
#### Bug Fixes
- (**tests**) remove non-existent file import - (f94da48) - syioa
- can provide larger files than before - (11dadae) - syioa
- skip newlines in indent state - (85d918d) - syioa
#### Refactoring
- (**html-renderer**) implement proper escaping - (18d7549) - syioa
- (**tests**) ensure payloads are not out of bounds - (6abefdb) - syioa
- (**tests**) complete checking of various posibilities - (c43fe7d) - syioa
- (**tests**) ensure text payload idx is not out of bounds - (dfab82a) - syioa
- remove the unnecessary `_heading_content` from ts grammar - (9d3b7b4) - syioa
- ensure heading marker is always followed by a space - (52dc348) - syioa
- implement unordered lists - (cda2544) - syioa
- change link syntax - (d912a65) - syioa
- change bold marker to '**' and italic marker to '__' - (fd437e1) - syioa
- implement rendering of links - (1c7e6cd) - syioa
- remove the tests as they were redundant - (6b6d7c4) - syioa
- rename render to renderer in root.zig and main.zig - (0922c87) - syioa
- rewrite of the parser and tokenizer in tree sitter - (e59b055) - syioa
- expand test data - (187de73) - syioa
- add some basic tests - (305a921) - syioa
#### Miscellaneous Chores
- add zig-pkg in .gitignore - (fc507dc) - syioa
- update README.md - (e846f1b) - syioa

- - -

## 0.1.1 - 2026-06-14
#### Features
- basic cli args parsing - (4050524) - syioa
#### Refactoring
- relocate printAST function - (4d4b268) - syioa
- improve imports - (eb8fba2) - syioa
- rename `tests` folder to `markdown_documents` - (2ea9599) - syioa

- - -

## 0.1.0 - 2026-06-13
#### Features
- implement basic conversion strategy - (84faae6) - syioa
#### Bug Fixes
- (**parser**) index out of bounds error - (aae32fe) - syioa
#### Performance Improvements
- (**lexer**) consume indents and uli faster - (20df4f7) - syioa
#### Refactoring
- (**parser**) consume 2 newlines after a unordered list item - (b771619) - syioa
- (**parser**) consume 2 newlines after the paragraph - (5d91d1d) - syioa
- (**parser**) rename ul_payloads to uli_payloads - (9cfb400) - syioa

- - -

## 0.0.4 - 2026-06-08
#### Features
- add unordered lists - (4d962f8) - syioa
#### Bug Fixes
- (**parser**) index out of bounds error - (0050283) - syioa
- (**parser**) use unused return value - (fe2bd47) - syioa
#### Documentation
- update Features spec - (c1ecf29) - syioa
#### Refactoring
- (**ast**) lower case of Document - (6736262) - syioa
- (**parser**) ditch inferred error types - (3c2ff16) - syioa
- (**parser**) add a new newline Node - (622a349) - syioa
#### Miscellaneous Chores
- update README.md - (f91b65c) - syioa
#### Style
- format parser.zig - (487d1bf) - syioa

- - -

## 0.0.2 - 2026-06-06
#### Features
- implement blockquotes - (43c19bc) - syioa
#### Refactoring
- new paragraphs start with two newlines - (4db7e38) - syioa

- - -

## 0.0.1 - 2026-06-05
#### Features
- (**lexer**) add support for escaping '*' and '_' - (6432e97) - syioa
- (**lexer**) stateful tokenizer - (61e281c) - syioa
- pass cli arguments - (cc07eb4) - syioa
- support for escaping chars - (002d9a8) - syioa
- add parent_idx for knowing direct children of nodes - (32b3886) - syioa
- make first_child an optional - (9b6ac22) - syioa
- support links - (1a2d7c6) - syioa
- support for italics - (097bed0) - syioa
- add more headings - (b57fef5) - syioa
- first iteration of working lexer and parser - (1ba0591) - syioa
#### Bug Fixes
- (**parser**) add a deinit function to release memory if not using ArenaAllocator - (3bfc5cb) - syioa
- unhandled enum variants in `Parser.parseParagraph` - (137051e) - syioa
- discard headings on the middle of a paragraph or line - (c0cecb7) - syioa
#### Documentation
- update README.md - (12d61b5) - syioa
#### Refactoring
- (**ast**) rename num_children to num_descendants - (20ea6c4) - syioa
- (**lexer**) change bold marker to '*' and italic marker to '_' - (34cc6e6) - syioa
- (**parser**) remove redundant return statement in consumeEscapeChar - (86cf1a8) - syioa
- rename docs folder to tests - (682607f) - syioa
- split the markdown content away from the logic - (1f9e864) - syioa
- introduce some helper methods - (080442e) - syioa
- split the Tokenizer code - (62c78a7) - syioa
- better organization of namespaces - (0db4e44) - syioa
- change payload from a tagged union to Structure of Arrays - (aeb500a) - syioa
#### Miscellaneous Chores
- (**cog**) add pre_bump_hooks - (19dfeda) - syioa
- fix a typo in cog.toml - (e6cf95e) - syioa
- initial commit - (154f78e) - syioa
#### Style
- format - (7693851) - syioa
- fix formatting - (a19b44f) - syioa
- format tokenizer.zig - (82338fe) - syioa

- - -

Changelog generated by [cocogitto](https://github.com/cocogitto/cocogitto).