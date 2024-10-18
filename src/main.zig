const std = @import("std");
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
        std.log.info("{s}", .{usage_init});
        fatal("expected command argument", .{});
    }

    const cmd = args[1];
    const cmd_args = args[2..];
    if (mem.eql(u8, cmd, "-h") or mem.eql(u8, cmd, "--help")) {
        try io.getStdOut().writeAll(usage_init);
        return cleanExit();
    } else if (mem.eql(u8, cmd, "init")) {
        return cmdInit(gpa, cmd_args);
    } else {
        std.log.info("{s}", .{usage_init});
        fatal("unrecognized command: '{s}'", .{cmd});
    }
}

fn cmdInit(gpa: Allocator, args: []const []const u8) !void {
    const s = fs.path.sep_str;
    const path_prefix = "lib" ++ s ++ "init" ++ s;

    if (args.len == 0) {
        try copyTemplatesToCwd(gpa, path_prefix ++ "default");
    }

    for (args) |arg| {
        if (mem.startsWith(u8, arg, "-")) {
            if (mem.eql(u8, arg, "-h") or mem.eql(u8, arg, "--help")) {
                try io.getStdOut().writeAll(usage_init);
                return cleanExit();
            } else if (mem.eql(u8, arg, "-m") or mem.eql(u8, arg, "--minimal")) {
                try copyTemplatesToCwd(gpa, path_prefix ++ "minimal");
            } else if (mem.eql(u8, arg, "-f") or mem.eql(u8, arg, "--flake")) {
                try copyTemplatesToCwd(gpa, path_prefix ++ "flake");
            } else {
                fatal("unrecognized parameter: '{s}'", .{arg});
            }
        } else {
            fatal("unexpected extra parameter: '{s}'", .{arg});
        }
    }

    return cleanExit();
}

pub fn copyTemplatesToCwd(allocator: Allocator, template_path: []const u8) !void {
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
                std.log.info("Creating file: {s}\n", .{entry.path});
                const src_file = try template_dir.openFile(entry.path, .{ .mode = .read_write });
                defer src_file.close();

                const dest_file = cwd.createFile(entry.path, .{ .read = true, .exclusive = true }) catch |err| {
                    if (err == error.PathAlreadyExists) {
                        std.log.info("File already exists, skipping: {s}\n", .{entry.path});
                        continue;
                    }
                    return err;
                };
                defer dest_file.close();

                const src_size = try src_file.getEndPos();
                _ = try src_file.copyRange(0, dest_file, 0, src_size);
            },
            .directory => {
                std.log.info("Creating directory: {s}\n", .{entry.path});
                try cwd.makePath(entry.path);
            },
            else => {},
        }
    }
}

const usage_init =
    \\Usage: zo init
    \\
    \\   Initializes a `zig build` project in the current working
    \\   directory.
    \\
    \\Options:
    \\  -h, --help             Print this help and exit
    \\  -m, --minimal          Initializes a minimal `zig build` project
    \\  -f, --flake            Adds a basic Nix Flake for creating a Zig dev environment
    \\
    \\
;

pub fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    process.exit(1);
}
