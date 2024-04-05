const std = @import("std");
const Allocator = std.mem.Allocator;

var mock_bytes_iteration: usize = 0;

// zig fmt: off
const bytes_array = [_]u8{
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
    0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F,
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
    0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
    0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
};
// zig fmt: on
pub const mock_bytes: []const u8 = &bytes_array;

/// Initialize mock
pub fn init(
    llrwPtr: *(*const fn (u8) u8),
    cehPtr: *(*const fn () void),
    celPtr: *(*const fn () void),
    csnhPtr: *(*const fn () void),
    csnlPtr: *(*const fn () void),
) void {
    mock_bytes_iteration = 0;
    llrwPtr.* = llRw;
    cehPtr.* = ceH;
    celPtr.* = ceL;
    csnhPtr.* = csnH;
    csnlPtr.* = csnL;
}

pub fn skip(num: usize) void {
    mock_bytes_iteration += num;
}

pub fn getMockWithOffset(allocator: Allocator, len: u32, offset: u32) ![]const u8 {
    var new_mock = try allocator.alloc(u8, len);
    // defer allocator.free(new_mock);

    for (0..new_mock.len) |i| {
        new_mock[i] = mock_bytes[(offset + i) % mock_bytes.len];
    }
    return new_mock;
}

pub fn getLastByte() u8 {
    return mock_bytes[mock_bytes_iteration - 1];
}

pub fn llRw(tx: u8) u8 {
    _ = tx;
    if (mock_bytes_iteration == mock_bytes.len) {
        mock_bytes_iteration = 0;
    }
    mock_bytes_iteration += 1;
    return mock_bytes[mock_bytes_iteration - 1];
}

pub fn ceL() void {}

pub fn ceH() void {}

pub fn csnL() void {}

pub fn csnH() void {}
