/**
 * @file A parser for the zm markup language
 * @author syioa <lalitsingh.micro@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check


export default grammar({
  name: "zm",

  extras: _ => [],
  rules: {
    document: $ => repeat(
      seq(choice($._block_content, repeat($._inline_content)), $.newline),
    ),
    _inline_content: $ => choice(
      $.bold,
      $.italic,
      $.link,
      $.text,
    ),
    _block_content: $ => choice(
      $.heading,
    ),

    // #region _inline_content
    text: _ => token(repeat1(choice(
      /[^\n\\\#\[\]\(\)\*\_]+/, // normal text
      seq('\\', /./) // escape
    ))),
    
    url: _ => token(repeat1(choice(
      /[^\s\\)]+/, // url matcher
      seq('\\', /./), // escape
    ))),

    bold: $ => seq(
      '*',
      repeat1(choice(
        $.italic,
        $.link,
        $.text,
      )),
      '*',
    ),
    italic: $ => seq(
      '_',
      repeat1(choice(
        $.bold,
        $.link,
        $.text,
      )),
      '_',
    ),
    link: $ => seq(
      '[',
      $.text,
      '](',
      $.url,
      ')'
    ),
    // #endregion

    // #region _block_content
    heading_marker: _ => /#{1,6}/,
    _heading_content: $ => repeat1($._inline_content),
    heading: $ => (seq(
      $.heading_marker,
      $._heading_content,
    )),
    // #endregion

    // special tokens
    newline: _ => '\n',
  }
});
