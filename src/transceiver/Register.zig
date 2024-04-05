//! # Register interface to provide real and mocked version.
//! Provides a generic way to read and write registers.
const std = @import("std");
const Type = std.builtin.Type;
const assert = std.debug.assert;

const Register = @This();

ptr: *anyopaque,
vtable: *const VTable,

const VTable = struct {
    writeRegister: *const fn (*anyopaque) anyerror!void,
    readRegister: *const fn (*anyopaque) anyerror!void,
};

pub fn init(obj: anytype) Register {
    const Ptr = @TypeOf(obj);
    const PtrInfo = @typeInfo(Ptr);
    assert(PtrInfo == .Pointer);
    assert(PtrInfo.Pointer.size == .One);
    const alignment = PtrInfo.Pointer.alignment;
    const impl = struct {
        fn writeRegister(ptr: *anyopaque) anyerror!void {
            const self: Ptr align(alignment) = @ptrCast(@alignCast(ptr));
            try @constCast(self).writeRegister();
        }
        fn readRegister(ptr: *anyopaque) anyerror!void {
            const self: Ptr align(alignment) = @ptrCast(@alignCast(ptr));
            try @constCast(self).readRegister();
        }
    };
    return .{
        .ptr = @constCast(obj),
        .vtable = &.{
            .writeRegister = impl.writeRegister,
            .readRegister = impl.readRegister,
        },
    };
}

pub fn writeRegister(self: *Register) !void {
    try self.vtable.writeRegister(self.ptr);
}

pub fn readRegister(self: *Register) !void {
    try self.vtable.readRegister(self.ptr);
}

pub const Info = struct {
    bytes: u8,
    index: u8,
};
