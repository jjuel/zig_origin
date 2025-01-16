const std = @import("std");
const embed = @import("commands/embed.zig");
const init = @import("commands/init.zig");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const process = std.process;
const Allocator = mem.Allocator;
const cleanExit = std.process.cleanExit;

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    defer _ = general_purpose_allocator.deinit();

    const args = try process.argsAlloc(gpa);
    defer process.argsFree(gpa, args);
    if (args.len <= 1) {
        std.log.info("{s}", .{usage});
        fatal("expected command argument", .{});
    }

    const cmd = args[1];
    const cmd_args = args[2..];
    if (mem.eql(u8, cmd, "-h") or mem.eql(u8, cmd, "--help") or mem.eql(u8, cmd, "help")) {
        try io.getStdOut().writeAll(usage);
        return cleanExit();
    } else if (mem.eql(u8, cmd, "init")) {
        return init.cmdInit(gpa, cmd_args);
    } else if (mem.eql(u8, cmd, "embed")) {
        return embed.cmdEmbed(gpa, cmd_args);
    } else {
        std.log.info("{s}", .{usage});
        fatal("unrecognized command: '{s}'", .{cmd});
    }
}

pub fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    process.exit(1);
}

const usage =
    \\Usage: zo <COMMAND>
    \\
    \\Commands:
    \\  init:   Initializes a `zig build` project in the current working directory.
    \\  embed:  Useful commands for working with Zig in embedded environments.
    \\  help:   Print this help and exit.
    \\
    \\Options:
    \\  -h, --help      Print this help and exit.
    \\
;
