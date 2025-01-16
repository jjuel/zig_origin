const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    // .rp2xxx = true,
    // .stm32 = true,
});

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const firmware = mb.add_firmware(.{
        .name = "*",
        // Set the target here for your particular board.
        // Here are two possible examples for STM32 or Pico2.
        // .target = mb.ports.rp2xxx.boards.raspberrypi.pico2,
        // .target = mb.ports.stm32.chips.STM32F103C8,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    mb.install_firmware(firmware, .{});

    mb.install_firmware(firmware, .{ .format = .elf });
}
