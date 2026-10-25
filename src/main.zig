const std = @import("std");
const builtin = @import("builtin");
const sqlite = @import("sqlite");

pub const version = "0.1.0";

pub fn main(init: std.process.Init) !void {
    var buf: [256]u8 = undefined;
    var w = std.Io.File.stdout().writer(init.io, &buf);
    const out = &w.interface;
    try out.print("soko {s} ({s}-{s})\n", .{
        version,
        @tagName(builtin.target.os.tag),
        @tagName(builtin.target.cpu.arch),
    });
    try out.print("sqlite {s}\n", .{std.mem.span(sqlite.sqlite3_libversion())});
    try out.flush();
}

test "sqlite reports a version" {
    try std.testing.expect(std.mem.eql(u8, std.mem.span(sqlite.sqlite3_libversion()), "3.54.1"));
}
