const std = @import("std");
const Allocator = std.mem.Allocator;

const testing = std.testing;
const testenv = @import("testenv");
const log = std.log.scoped(.zig_rf24);

/// **Implement** the deactivation of the CE pin
pub var ceL: *const fn () void = celImpl;

/// **Implement** the activation of the CE pin
pub var ceH: *const fn () void = cehImpl;

/// **Implement** the deactivation of the CSN pin
pub var csnL: *const fn () void = csnlImpl;

/// **Implement** the activation of the CSN pin
pub var csnH: *const fn () void = csnhImpl;

/// **Implement** reading and writing to the SPI bus
pub var llRw: *const fn (u8) u8 = llrwImpl;

pub const Transceiver = @import("Transceiver.zig");

test {
    testing.refAllDeclsRecursive(@This());
}

pub fn celImpl() void {
    std.debug.panic("ceL hasn't been implemented!", .{});
}

pub fn cehImpl() void {
    std.debug.panic("ceH hasn't been implemented!", .{});
}

pub fn csnlImpl() void {
    std.debug.panic("csnL hasn't been implemented!", .{});
}

pub fn csnhImpl() void {
    std.debug.panic("csnH hasn't been implemented!", .{});
}

pub fn llrwImpl(_: u8) u8 {
    std.debug.panic("llRw hasn't been implemented!", .{});
    noreturn;
}
