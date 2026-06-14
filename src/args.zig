const std = @import("std");

pub const ParseArgsError = error {
    MissingOutputFilePath,
    MissingInputFilePath,
};

pub const Args = struct {
    input: ?[]const u8 = null,
    output: ?[]const u8 = null,
};

/// parses the cli args
pub fn parseArgs(args_iterator: *std.process.Args.Iterator) ParseArgsError!Args {
    _ = args_iterator.next();

    var args = Args {};

    while (args_iterator.next()) |arg| {
        if (std.mem.eql(u8, arg, "-o")) {
            args.output = args_iterator.next() orelse return error.MissingOutputFilePath;
        } else if (arg.len > 0 and arg[0] != '-') {
            args.input = arg;
        }
    }

    if (args.output == null and args.input != null) {
        args.output = args.input;
    } else {
        return error.MissingInputFilePath;
    }

    return args;
}

