const std = @import("std");

pub const ParseArgsError = error {
    MissingOutputFilePath,
    MissingInputFilePath,
    UnexpectedArguments
};

pub const Args = struct {
    input: ?[]const u8 = null,
    output: ?[]const u8 = null,
    help: bool = false,
    version: bool = false,
    stdout: bool = false,
};

/// parses the cli args
pub fn parseArgs(args_iterator: *std.process.Args.Iterator) ParseArgsError!Args {
    _ = args_iterator.next();

    var args = Args {};

    while (args_iterator.next()) |arg| {
        if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
            if (args_iterator.next()) |output_file| {
                if (std.mem.startsWith(u8, output_file, "-")) return error.MissingOutputFilePath;
                args.output = output_file;
            } else return error.MissingOutputFilePath;
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            args.help = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            args.version = true;
        } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--stdout")) {
            args.stdout = true;
        } else if (arg.len > 0 and arg[0] != '-') {
            args.input = arg;
        } else return error.UnexpectedArguments;
    }

    if (args.input == null) {
        if (args.help or args.version or args.stdout) {} else return error.MissingInputFilePath;
    }

    return args;
}

