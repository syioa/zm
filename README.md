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

Following features are supported —

###### Bold And Italic

Use `**` chars around the word, phrase or sentence for **bold**.

Use `__` chars around the word, phrase or sentence for _italic_.

###### Links

Links are supported via this syntax `$link[text](url)`.

Remember that the text can't contain any bold or italics or other links.
To make a link bold(/italic) wrap the bold(/italic) chars around the whole link syntax.

###### Unordered & Ordered Lists

**Unordered Lists** start with usual `-` and a space is necessary after the hyphen(-). Unordered list items only span a single line and a newline is necessary after one.

To start **Ordered Lists** you first have to write `$ol` and in the next line use numbers and a period(.) followed by a space to start a ordered list item. They too span a single line and a newline is necessary after one.

Both **Unordered & Ordered List Items** are nestable and you can mix Unordered and Ordered List Items. But remember that in the following eg. (though it is discouraged to write something like this, but still it's a feature)

```md
- Item 1
1. Item 2
```

`Item 1` will have a order number 1 and `Item 2` will have order number 2. (Yes even unordered lists have order numbers but they are not shown, unless you write some custom js code in the generated HTML file).

###### Frontmatter

For the frontmatter this project uses [KDL](https://kdl.dev/). The usual `---` markers are supported for the start and end of the frontmatter content. The following is an eg.

```zm
---
- {
    title "Hello World"
}
---

```

Visit [KDL](https://kdl.dev/) to know the KDL syntax. Though remember that in `zm` frontmatter, there could only be one node at the top level of your KDL syntax and the title value is used for the title of the HTML document generated.

###### Variables

All the properties defined in the frontmatter can be used as variables throughout the document.

Use the syntax `{variable_name}`. There could be an optional space between the curly brackets and the variable name.

Nested variables and lists can be indexed via dot(`.`) syntax like this `{ some_parent.named_child.0 }`. (Yes lists are indexed via dots not square brackets(`[]`) like in most programming languages. )

###### Blockquote

`Blockquote`s in `zm` is very different to markdown. `Blockquote`s in `zm` markup produce a `<blockquote>` tag in the resulting HTML.

The syntax is similar to markdown, though. Just use `>` followed by a space.

>[!note]
> Nested `blockquote`s are not supported as it is weird to have nested `<blockquote>` tags in HTML.


## Usage

Currently this program does not produce any `.html` or any other file.
It just parses and renders(or converts) the provided `zm` file to HTML and prints the output to **stdout**.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Acknowledgements

- [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) for parsing the `zm` syntax.
- [KDL and its Community](https://kdl.dev/) for the frontmatter.

