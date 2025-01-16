const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const process = std.process;
const Allocator = mem.Allocator;
const cleanExit = std.process.cleanExit;

const InitOptions = struct {
    vcs: ?[]const u8 = null,
};

pub fn cmdEmbed(gpa: Allocator, args: []const []const u8) !void {
    if (args.len <= 1) {
        std.log.info("{s}", .{usage_embed});
        fatal("expected command argument", .{});
    }

    const cmd = args[0];
    const cmd_args = args[1..];
    if (mem.eql(u8, cmd, "-h") or mem.eql(u8, cmd, "--help")) {
        try io.getStdOut().writeAll(usage_embed);
        return cleanExit();
    } else if (mem.eql(u8, cmd, "init")) {
        return cmdEmbedInit(gpa, cmd_args);
    } else {
        std.log.info("{s}", .{usage_embed});
        fatal("unrecognized command: '{s}'", .{cmd});
    }
}

fn cmdEmbedInit(gpa: Allocator, args: []const []const u8) !void {
    const s = fs.path.sep_str;
    const path_prefix = "lib" ++ s ++ "embed" ++ s ++ "init" ++ s;
    var options = InitOptions{};
    var templates_copied = false;

    if (args.len == 0) {
        try copyTemplatesToCwd(gpa, path_prefix ++ "default");
        templates_copied = true;
    }

    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (mem.startsWith(u8, arg, "-")) {
            if (mem.eql(u8, arg, "-h") or mem.eql(u8, arg, "--help")) {
                try io.getStdOut().writeAll(usage_embed_init);
                return cleanExit();
            } else if (mem.eql(u8, arg, "--vcs")) {
                if (i + 1 >= args.len) {
                    fatal("vcs option requires an argument", .{});
                }
                i += 1;
                options.vcs = args[i];
            } else {
                fatal("unrecognized parameter: '{s}'", .{arg});
            }
        } else {
            fatal("unexpected extra parameter: '{s}'", .{arg});
        }
    }

    if (options.vcs) |vcs| {
        try copyTemplatesToCwd(gpa, path_prefix ++ "default");
        try addVcsToDirectory(gpa, vcs);
    }

    return cleanExit();
}

fn copyTemplatesToCwd(allocator: Allocator, template_path: []const u8) !void {
    const exe_dir_path = try fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(exe_dir_path);

    const parent_dir_path = fs.path.dirname(exe_dir_path).?;

    const full_template_path = try fs.path.join(allocator, &[_][]const u8{ parent_dir_path, template_path });
    defer allocator.free(full_template_path);

    var template_dir = try fs.openDirAbsolute(full_template_path, .{ .iterate = true });
    defer template_dir.close();

    var cwd = fs.cwd();

    var walker = try template_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        switch (entry.kind) {
            .file => {
                std.log.info("Creating file: {s}", .{entry.path});
                const src_file = try template_dir.openFile(entry.path, .{ .mode = .read_write });
                defer src_file.close();

                const dest_file = cwd.createFile(entry.path, .{ .read = true, .exclusive = true }) catch |err| {
                    if (err == error.PathAlreadyExists) {
                        std.log.info("File already exists, skipping: {s}", .{entry.path});
                        continue;
                    }
                    return err;
                };
                defer dest_file.close();

                const src_size = try src_file.getEndPos();
                _ = try src_file.copyRange(0, dest_file, 0, src_size);
            },
            .directory => {
                std.log.info("Creating directory: {s}", .{entry.path});
                try cwd.makePath(entry.path);
            },
            else => {},
        }
    }
}

fn addVcsToDirectory(allocator: Allocator, arg: []const u8) !void {
    var result: anyerror!void = undefined;

    if (mem.eql(u8, arg, "jj")) {
        result = runCommand(allocator, &.{ "jj", "git", "init" });
    } else if (mem.eql(u8, arg, "git")) {
        result = runCommand(allocator, &.{ "git", "init" });
    } else if (mem.eql(u8, arg, "hg")) {
        result = runCommand(allocator, &.{ "hg", "init" });
    } else {
        fatal("{s} vcs is not currently supported.", .{arg});
    }

    if (result) |_| {
        std.log.info("{s} repository initialized successfully", .{arg});
    } else |err| {
        switch (err) {
            error.FileNotFound => fatal("The {s} command was not found. Please ensure it's installed in your PATH.", .{arg}),
            else => return err,
        }
    }
}

fn runCommand(allocator: Allocator, argv: []const []const u8) !void {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
    });

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        std.log.err("Command failed with exit code: {}", .{result.term.Exited});
        if (result.stderr.len > 0) {
            std.log.err("Error output: {s}", .{result.stderr});
        }

        return error.CommandFailed;
    }
}

const usage_embed =
    \\Usage: zo embed <COMMAND>
    \\
    \\   Will be used to assist with embedded Zig projects.
    \\
    \\Commands:
    \\  init:       Initializes a basic embedded Zig project using MicroZig.
    \\
    \\Options:
    \\  -h, --help      Print this help and exit.
    \\
    \\
;

const usage_embed_init =
    \\Usage: zo embed init
    \\
    \\   Initializes a template MicroZig project in the current working
    \\   directory.
    \\
    \\Options:
    \\  -h, --help      Print this help and exit.
    \\      --vcs       Initializes a repo for the provided VCS.
    \\
    \\
;

pub fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    process.exit(1);
}
