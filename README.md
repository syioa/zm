# zm

> A powerful, simple and easy to use markup language.
> Building on top of markdown. Ambitions of becoming a PKMS, Personal Blogging System, etc.

> [!note]
> Markdown(CommonMark Specification) is very weird and complex(sometimes) so I don't intend to support CommonMark Specification and would deliberately try to make a lot of things simpler to write and parse.
>
> `zm` envisions to be different from markdown in my ways but sometimes embracing markdown's simplicity.

> [!warning]
> Many features are not complete yet!


## Installation

Currently no package manager is supported. You need to build this project yourself.

All the dependencies will be fetched by the Zig compiler.


## Features

>[!note]
> Newlines and blank lines are two different things and both of them are not used interchangeably in this document.

>[!note]
> **Inline & Block Functions** are special syntaxes.
>
> **Inline Function** don't need a newline and you can continue to write more text in the same line but **Block Functions** do need a newline.
>
> Start an **Inline function** with `@` symbol and **Block Functions** with `#` symbol (remember headings are not functions though they start with `#`s).
>
> If there is a space after `@` symbol it just acts like normal text,
> but `#` symbol doesn't since `#` is also used for heading and if you want to include it in your markup you need to escape it like `\#`.

Following features are supported —

###### Escaping

**Every special char** needs escaping if you want to see it in the final output.

###### Bold And Italic

Use `*` chars around the word, phrase or sentence for **bold**.

Use `_` chars around the word, phrase or sentence for _italic_.

###### Links

Links are supported via this syntax `@link[text](url)`.

Remember that the text can't contain any bold or italics or other links.
To make a link bold/italic wrap the bold/italic chars around the whole link syntax.

###### Ordered & Unordered Lists

**Unordered Lists** are available as **Block Function** just use `#ul[` and in a newline use **Unordered List Item** syntax; close the **Unordered List Block Function** with `]`

**Unordered List Item** start with usual `-` and a space is necessary after the hyphen(-). Unordered list items only span a single line and a newline is necessary after one.

Similarly an **Ordered List Block Function** looks like `#ol[\n...\n]`.
The `newline` chars are not typos.

**Ordered List Item** start with numbers followed by a dot(`.`) and a space. You can use any whole number and proper numbering will be assigned by `zm` compiler.

Both **Unordered & Ordered List Items** are nestable and you can mix Unordered and Ordered List Items. But remember that in the following example (though it is discouraged to write something like this, but still it's a feature)

```md
#ul[
- Item 1
1. Item 2
]
```

`Item 1` will have a order number 1 and `Item 2` will have order number 2. (Yes even unordered lists have order numbers but they are not shown, unless you write some custom js code in the generated HTML file).

###### Frontmatter

For the frontmatter this project uses [KDL](https://kdl.dev/). The usual `---` markers are supported for the start and end of the frontmatter content. eg.

```zm
---
title "Hello World"
author "some name"
---

```

Visit [KDL](https://kdl.dev/) to know the KDL syntax. Though remember that in `zm` frontmatter, the title value is used for the title of the HTML document generated.

###### Variables

All the properties defined in the frontmatter can be used as variables throughout the document.

Use the syntax `{variable_name}`. There could be an optional space between the curly brackets and the variable name.

Nested variables and lists can be indexed via dot(`.`) syntax like this `{ some_parent.named_child.0 }`. (Yes lists are indexed via dots not square brackets(`[]`) unlike in most programming languages. )

###### Blockquote

**Blockquotes** in `zm` are just used for quotations.

The syntax is similar to markdown, though. Just use `>` followed by a space.

If you want to cite the author of the quote just put the name of the author between square brackets(`[]`) in a new line. eg.

```zm
> Simplicity is the ultimate sophistication.
[Leonardo da Vinci]
```

>[!note]
> Nested `blockquote`s are not supported as it would be weird to have nested quotations.

###### Separator

Separators are only to be used as thematic breaks or [scene breaks](https://en.wikipedia.org/wiki/Section_(typography)).

It is a block function, syntax is `#sep`.


## Usage

`zm` executable either prints its output to `stdout` or a file provided by the user.

Run it with `-o`/`--output` `<file_name>` to write to a file.

If you want to print to `stdout`, pass the `-s`/`--stdout` flag.

In both the cases an input file must be provided which contains proper `zm` markup.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Acknowledgements

- [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) for parsing the `zm` syntax.
- [KDL and its Community](https://kdl.dev/) for the frontmatter.
- [Catppuccin](https://catppuccin.com/) for amazing color palette.

