//! Mock of `Register` for testing
const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

const MockRegister = @This();

const Register = @import("../../transceiver/Register.zig");

const VTable = struct {
    fromRegister: *const fn (*anyopaque, []const u8) anyerror!void,
    toRegister: *const fn (*anyopaque) ?[]const u8,
};

ptr: *anyopaque,
vtable: *const VTable,

e_in: ?[]const u8,
e_out: ?[]const u8,
bytes: u8,
register_index: u8,

pub fn init(
    expect_in: ?[]const u8,
    expect_out: ?[]const u8,
    bytes: u8,
    register_index: u8,
    obj: anytype,
) MockRegister {
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
        .e_in = expect_in,
        .e_out = expect_out,
        .bytes = bytes,
        .register_index = register_index,

        .ptr = obj,
        .vtable = &.{
            .fromRegister = impl.fromRegister,
            .toRegister = impl.toRegister,
        },
    };
}

pub fn register(self: *MockRegister) Register {
    return Register.init(self);
}

fn fromRegister(self: *MockRegister, data: []const u8) !void {
    try self.vtable.fromRegister(self.ptr, data);
}

fn toRegister(self: *MockRegister) ?[]const u8 {
    return self.vtable.toRegister(self.ptr);
}

pub fn writeRegister(self: *MockRegister) !void {
    if (self.e_in == null) {
        return error.MustNotBeCalled;
    }

    const data = self.toRegister();

    if (self.bytes == 0) {
        if (self.e_in.?.len != 0) {
            return error.TestingDataMismatch;
        }
        try testing.expect(data == null or data.?.len == 0);
        return;
    }

    if (data == null) {
        return error.ExpectedDataMismatch;
    }

    try testing.expectEqualSlices(u8, self.e_in.?, data.?);
}

pub fn readRegister(self: *MockRegister) !void {
    if (self.bytes == 0) {
        return error.MustNotHaveData;
    }

    if (self.e_out == null) {
        return error.MustNotBeCalled;
    }

    try self.fromRegister(self.e_out.?);
}
