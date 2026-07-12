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
    document: $ => repeat(seq(
      choice($._block_content, repeat($._inline_content)),
      $.newline,
    )),
    _inline_content: $ => choice(
      $.bold,
      $.italic,
      $.link,
      alias($._normal_text, $.text),
    ),
    _block_content: $ => choice(
      $.heading,
      $.unordered_list,
      $.ordered_list,
    ),

    // #region _inline_content
    // the following 2 nodes are meant to be used as aliases
    // never use them directly
    text: _ => token('don\'t use me'),
    attr: _ => token('don\'t use me'),
    _normal_text: _ => token(repeat1(choice(
      /[^\n\\\#\*\_\$\-]+/,
      seq('\\', /./) // escape
    ))),
    _link_text: _ => token(repeat1(choice(
      /[^\n\\\]]+/,
      seq('\\', /./) // escape
    ))),

    url: _ => token(repeat1(choice(
      /[^\s\\)]+/, // url matcher
      seq('\\', /./), // escape
    ))),

    bold: $ => seq(
      '**',
      repeat1(choice(
        $.italic,
        $.link,
        alias($._normal_text, $.text),
      )),
      '**',
    ),
    italic: $ => seq(
      '__',
      repeat1(choice(
        $.bold,
        $.link,
        alias($._normal_text, $.text),
      )),
      '__',
    ),
    link: $ => seq(
      '$link',
      '[',
      alias($._link_text, $.text),
      '](',
      $.url,
      ')'
    ),
    // #endregion

    // #region _block_content
    heading_marker: _ => /#{1,6}/,
    heading: $ => (seq(
      $.heading_marker,
      /\ /,
      repeat1($._inline_content),
    )),

    unordered_list: $ => seq(
      repeat1($.unordered_list_item),
    ),
    unordered_list_item: $ => seq(
      optional(alias(token(repeat('  ')), $.attr)),
      token(/\-/),
      token(/\ /),
      repeat1($._inline_content),
      $.newline,
    ),

    ordered_list: $ => seq(
      token(/\$ol/),
      /\n/,
      repeat1($.ordered_list_item),
    ),
    ordered_list_item: $ => seq(
      optional(
        alias(token( repeat('  ') ), $.attr)
      ),
      /\d+\./,
      /\ /,
      repeat1($._inline_content),
      $.newline,
    ),
    // #endregion

    // special tokens
    newline: _ => '\n',
  }
});
