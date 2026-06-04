const std = @import("std");

pub const TokenType = enum {
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    bold_marker,
    italic_marker,
    newline,
    text,
    link_open,
    link_mid,
    link_close,
};

pub const State = enum {
    link_text,
    link_url,
    none,
};

pub const Token = struct {
    type: TokenType,
    slice: []const u8,
};

pub const Tokenizer = struct {
    input: []const u8,
    index: usize = 0,
    /// Specifies the current tokenizing state
    state: State = .none,

    pub fn next(self: *Tokenizer) ?Token {
        if (self.index >= self.input.len) return null;

        const start = self.index;
        const char = self.input[self.index];

        if (self.atLineStart()) {
            if (self.matchBlockToken(char, start)) |token| return token;
        }

        if (self.matchInlineToken(char, start)) |token| return token;

        //TODO: check if infinite loops are possible

        // Text fallback
        return self.consumeText(start);
    }

    fn matchBlockToken(self: *Tokenizer, char: u8, start: usize) ?Token {
        if (char == '#' and self.state == .none) {
            if (self.matches("###### ")) return self.makeToken(.h6, 7, start);
            if (self.matches("##### ")) return self.makeToken(.h5, 6, start);
            if (self.matches("#### ")) return self.makeToken(.h4, 5, start);
            if (self.matches("### ")) return self.makeToken(.h3, 4, start);
            if (self.matches("## ")) return self.makeToken(.h2, 3, start);
            if (self.peek(1) == ' ') return self.makeToken(.h1, 2, start);
        }

        return null;
    }

    fn matchInlineToken(self: *Tokenizer, char: u8, start: usize) ?Token {
        if (self.state == .none) {
            if (char == '\n') return self.makeToken(.newline, 1, start);
            if (char == '*') return self.makeToken(.bold_marker, 1, start);
            if (char == '_') return self.makeToken(.italic_marker, 1, start);
            if (char == '[') {
                self.state = .link_text;
                return self.makeToken(.link_open, 1, start);
            }
        }
        if (self.state == .link_text) {
            if (self.matches("](")) {
                self.state = .link_url;
                return self.makeToken(.link_mid, 2, start);
            }
        }
        if (self.state == .link_url) {
            if (char == ')') {
                self.state = .none;
                return self.makeToken(.link_close, 1, start);
            }
        }
        return null;
    }

    fn consumeText(self: *Tokenizer, start: usize) Token {
        var char = self.input[self.index];

        outer: while (self.index < self.input.len) {
            self.consumeEscapeChar(self.input[self.index]);
            char = self.input[self.index];

            switch (self.state) {
                .none => {
                    switch (char) {
                        '*', '_', '[', '\n' => break :outer,
                        else => {},
                    }
                },
                .link_text => {
                    if (self.matches("](")) break :outer;
                },
                .link_url => {
                    if (char == ')') break :outer;
                },
            }

            self.index += 1;
        }
        return Token{ .type = .text, .slice = self.input[start..self.index] };
    }

    fn consumeEscapeChar(self: *Tokenizer, char: u8) void {
        if (char == '\\') {
            switch (self.peek(1)) {
                '[', ']', '(', ')', '\\', '*', '_' => {
                    self.index += 2;
                },
                else => {},
            }
        }
    }

    fn makeToken(self: *Tokenizer, tag: TokenType, len: usize, start: usize) Token {
        self.index += len;
        return Token{ .type = tag, .slice = self.input[start..self.index] };
    }

    fn peek(self: *Tokenizer, offset: usize) u8 {
        const target_index = self.index + offset;
        if (target_index >= self.input.len) return 0;
        return self.input[target_index];
    }

    fn atLineStart(self: *Tokenizer) bool {
        if (self.index == 0) return true;
        return if (self.input[self.index - 1] == '\n') true else false;
    }

    fn matches(self: *Tokenizer, expected: []const u8) bool {
        const end = self.index + expected.len;
        if (end > self.input.len) return false;
        return std.mem.eql(u8, self.input[self.index..end], expected);
    }
};
