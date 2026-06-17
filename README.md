# zm

> A powerful, simple and easy to use markup language.
> Building on top of markdown. Ambitions of becoming a PKMS, Personal Blogging System, etc.

> [!note]
> Markdown(CommonMark Specification) is very weird and complex(sometimes) so I don't intend to support CommonMark Specification and would deliberately try to make a lot of things simpler to write and parse.
> This means that most of the markdown you write won't be necessarily compatible with `zm`.

> [!warning]
> Many features are not complete yet!

## Installation

Currently no package manager is supported. You need to build this project yourself.

There are no dependencies as of now except for the Zig compiler to compile the project.

## Features

Features are not complete yet. Still `zm` can tokenize and parse the following types of markup features -

- Bold via `*` wrapped around the word, phrase, or sentence.
- Italic via `_` wrapped around the word, phrase or sentence.
- Links via `[text](url)` syntax.
- Blockquotes via the usual `> ` syntax, remember that a space after the `>` is important, without it a blockquote won't be created.
- Unordered Lists via hyphen (`- `) syntax, also nested unordered lists are supported. Note that a space after `-` is important.


#### List of Deliberate Exclusions

- Nested blockquotes are not supported.
- Link text can't contain bold or italic modifiers, if you want to make your link bold, wrap the link with the modifier like this - `*[some text](https://someurl.com)*`.
- An Unordered List Item only ends if you leave a blank line otherwise it doesn't.

## Usage

Currently this program does not produce any `.html` or any other file.
It just parses and renders(or converts) the provided Markdown file to HTML and prints the output to **stdout**.

