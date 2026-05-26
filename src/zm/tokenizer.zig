pub const TokenType = enum {
    h1,
    h2,
    bold_marker,
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

        if (char == '\n') {
            self.index += 1;
            return Token{ .type = .newline, .slice = self.input[start..self.index] };
        }

        if (char == '*' and self.peek(1) == '*') {
            self.index += 2;
            return Token{ .type = .bold_marker, .slice = self.input[start..self.index] };
        }

        if (char == '#' and self.peek(1) == '#' and self.peek(2) == ' ') {
            self.index += 3;
            return Token{ .type = .h2, .slice = self.input[start..self.index] };
        }
        if (char == '#' and self.peek(1) == ' ') {
            self.index += 2;
            return Token{ .type = .h1, .slice = self.input[start..self.index] };
        }

        // Text fallback
        while (self.index < self.input.len) {
            const c = self.input[self.index];
            if (c == '\n') break;
            if (c == '*' and self.peek(1) == '*') break;
            if (c == '#' and ((self.peek(1) == ' ') or (self.peek(1) == '#' and self.peek(2) == ' '))) break;
            self.index += 1;
        }

        if (self.index == start) self.index += 1; // Prevent infinite loops

        return Token{ .type = .text, .slice = self.input[start..self.index] };
    }

    fn peek(self: *Tokenizer, offset: usize) u8 {
        const target_index = self.index + offset;
        if (target_index >= self.input.len) return 0;
        return self.input[target_index];
    }
};
