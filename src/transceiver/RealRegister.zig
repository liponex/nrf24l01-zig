//! # Register
//! Provides a generic way to read and write registers.\
//! For that function to work, the user must init csnL, csnH, llRw functions for library.
const std = @import("std");
const assert = std.debug.assert;

const Commands = @import("Commands.zig");

const lib = @import("../root.zig");

const RealRegister = @This();
const Error = error{
    /// Data is too large to be written
    DataTooLarge,
    /// You tries to write data to a 0-byte register
    NoDataExpected,
};

const Register = @import("Register.zig");

var csnL = lib.csnL;
var csnH = lib.csnH;
var llRw = lib.llRw;

const VTable = struct {
    fromRegister: *const fn (*anyopaque, []const u8) anyerror!void,
    toRegister: *const fn (*anyopaque) ?[]const u8,
};

ptr: *anyopaque,
vtable: *const VTable,

bytes: u8,
register_index: u8,

pub fn init(
    bytes: u8,
    register_index: u8,
    obj: anytype,
) RealRegister {
    const Ptr = @TypeOf(obj);
    const PtrInfo = @typeInfo(Ptr);
    assert(PtrInfo == .Pointer); // Must be a pointer
    assert(PtrInfo.Pointer.size == .One); // Must be a single-item pointer
    assert(@typeInfo(PtrInfo.Pointer.child) == .Struct); // Must point to a struct
    const alignment = PtrInfo.Pointer.alignment;
    const impl = struct {
        fn fromRegister(ptr: *anyopaque, data: []const u8) anyerror!void {
            const self: Ptr align(alignment) = @ptrCast(@alignCast(ptr));
            try self.fromRegister(data);
        }
        fn toRegister(ptr: *anyopaque) ?[]const u8 {
            const self: Ptr align(alignment) = @ptrCast(@alignCast(ptr));
            return self.toRegister();
        }
    };

    return .{
        .bytes = bytes,
        .register_index = register_index,

        .ptr = obj,
        .vtable = &.{
            .fromRegister = impl.fromRegister,
            .toRegister = impl.toRegister,
        },
    };
}

pub fn register(self: *RealRegister) Register {
    return Register.init(self);
}

fn fromRegister(self: *RealRegister, data: []const u8) !void {
    try self.vtable.fromRegister(self.ptr, data);
}

fn toRegister(self: *RealRegister) ?[]const u8 {
    return self.vtable.toRegister(self.ptr);
}

pub fn writeRegister(self: *RealRegister) !void {
    var reg = self.register_index;
    csnL();
    defer csnH();

    const data = self.toRegister();

    if (reg < Commands.w_register) {
        reg |= Commands.w_register;
    }

    _ = llRw(reg);
    if (data == null) {
        return;
    }

    if (data.?.len > 32 or self.bytes < data.?.len) {
        return Error.DataTooLarge;
    }

    if (self.bytes == 0 and data.?.len > 0) {
        return Error.NoDataExpected;
    }

    var i = data.?.len;
    while (self.bytes > 0 and i > 0) {
        i -= 1;
        _ = llRw(data.?[i]);
    }
}

pub fn readRegister(self: *RealRegister) !void {
    var reg = self.register_index;

    csnL();
    defer csnH();

    if (reg < Commands.r_register) {
        reg |= Commands.r_register;
    }

    _ = llRw(reg);
    var data = llRw(0);
    if (data == null) {
        return;
    }
    var i = self.bytes;
    while (i > 0) {
        i -= 1;
        data[i] = llRw(0);
    }
    try self.fromRegister(data);
}

/// Commands definitions
pub const Cmd = struct {
    /// Register read
    pub const r_register: u8 = 0b0000_0000;

    /// Register write
    pub const w_register: u8 = 0b0010_0000;

    /// (De)Activates R_RX_PL_WID, W_ACK_PAYLOAD, W_TX_PAYLOAD_NOACK features
    pub const activate: u8 = 0x0101_0000;

    /// Read RX-payload width for the top R_RX_PAYLOAD in the RX FIFO.
    pub const r_rx_pl_wid: u8 = 0x60;

    /// Read RX payload
    pub const r_rx_payload: u8 = 0b0110_0001;

    /// Write TX payload
    pub const w_tx_payload: u8 = 0b1010_0000;

    /// Write ACK payload
    pub const w_ack_payload: u8 = 0xA8;

    /// Write TX payload and disable AUTOACK
    pub const w_tx_payload_noack: u8 = 0xB0;

    /// Flush TX FIFO
    pub const flush_tx: u8 = 0xE1;

    /// Flush RX FIFO
    pub const flush_rx: u8 = 0xE2;

    /// Reuse TX payload
    pub const reuse_tx_pl: u8 = 0xE3;

    /// Lock/unlock exclusive features
    pub const lock_unlock: u8 = 0x50;

    /// No operation (used for reading status register)
    pub const nop: u8 = 0b1111_1111;
};
