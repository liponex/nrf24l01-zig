const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const testenv = b.createModule(.{
        .root_source_file = .{ .path = "src/test_enviroment.zig" },
    });

    _ = b.addModule("nrf24l01_zig", .{
        .root_source_file = .{ .path = "src/main.zig" },
    });

    const lib = b.addStaticLibrary(.{
        .name = "nrf24l01_zig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    _ = b.addModule("zig_rf24", .{
        .root_source_file = .{ .path = "src/root.zig" },
    });

    const lib_new = b.addStaticLibrary(.{
        .name = "zig_rf24",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib_new);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.root_module.addImport("testenv", testenv);
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const lib_new_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib_new_unit_tests.root_module.addImport("testenv", testenv);
    const run_lib_new_unit_tests = b.addRunArtifact(lib_new_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_lib_new_unit_tests.step);
}
