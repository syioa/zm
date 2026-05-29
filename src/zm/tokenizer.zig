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
};

pub const Token = struct {
    type: TokenType,
    slice: []const u8,
};

pub const Tokenizer = struct {
    input: []const u8,
    index: usize = 0,

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
        if (char == '#') {
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
        if (char == '\n') return self.makeToken(.newline, 1, start);
        if (self.matches("**")) return self.makeToken(.bold_marker, 2, start);
        if (self.matches("__")) return self.makeToken(.italic_marker, 2, start);
        return null;
    }

    fn consumeText(self: *Tokenizer, start: usize) Token {
        while (self.index < self.input.len) {
            const char = self.input[self.index];
            if (char == '\n' or self.matches("**") or self.matches("__")) break;
            self.index += 1;
        }
        return Token { .type = .text, .slice = self.input[start..self.index] };
    }

    fn makeToken(self: *Tokenizer, tag: TokenType, len: usize, start: usize) Token {
        self.index += len;
        return Token { .type = tag, .slice = self.input[start..self.index] };
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
