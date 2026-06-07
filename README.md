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

- Bold via `*` char wrapped around the word, phrase, or sentence.
- Italic via `_` char wrapped around the word, phrase or sentence.
- Links via `[text](url)` syntax.
- Blockquotes via the usual `> ` syntax, remember that a space after the `>` char is important, without it a blockquote won't be created.


#### List of Deliberate Exclusions

- Nested blocquotes are not supported.
- Link text can't contain bold or italic modifiers, if you want to make your link bold add the modifiers outside of the link like this - `*[some text](https://someurl.com)*`

## Usage

Currently this program does not produce any `.html` or any other file.
It's pretty basic and can only tokenize and parse a `.md` file.

