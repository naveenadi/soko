const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // SQLite is compiled from the vendored amalgamation so every target sees the
    // same C source; its declarations come from translate-c, not from a system
    // header. This is the C-interop proof for the whole project.
    const sqlite = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    sqlite.addIncludePath(b.path("vendor/sqlite"));
    sqlite.addCSourceFiles(.{
        .root = b.path("vendor/sqlite"),
        .files = &.{"sqlite3.c"},
        .flags = &.{
            "-std=c11",
            "-DSQLITE_ENABLE_FTS5",
            "-DSQLITE_ENABLE_RTREE",
            "-DSQLITE_OMIT_LOAD_EXTENSION",
        },
    });
    const sqlite_lib = b.addLibrary(.{
        .name = "sqlite3",
        .linkage = .static,
        .root_module = sqlite,
    });

    const sqlite_c = b.addTranslateC(.{
        .root_source_file = b.path("vendor/sqlite/sqlite3.h"),
        .target = target,
        .optimize = optimize,
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addImport("sqlite", sqlite_c.createModule());
    mod.linkLibrary(sqlite_lib);

    const exe = b.addExecutable(.{ .name = "soko", .root_module = mod });
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());
    b.step("run", "Run soko").dependOn(&run.step);

    const tests = b.addTest(.{ .root_module = mod });
    b.step("test", "Run unit tests").dependOn(&b.addRunArtifact(tests).step);
}
