//! Address Register
const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const Register = @import("../Register.zig");
const RxPipe = @import("../RxPipe.zig");

const Address = @This();

reg: Register = undefined,

pipe: Pipe = undefined,
pipe_relative_register: u8 = undefined,
pipe_relative_bytes: u8 = 0,

address: ?[]const u8 = null,

pub fn init(pipe: Pipe) Address {
    var self: Address = .{};
    self.pipe = pipe;
    self.pipe_relative_register = switch (pipe) {
        .pipe0 => 0x0A,
        .pipe1 => 0x0B,
        .pipe2 => 0x0C,
        .pipe3 => 0x0D,
        .pipe4 => 0x0E,
        .pipe5 => 0x0F,
        .tx => 0x10,
    };
    self.pipe_relative_bytes = switch (pipe) {
        .pipe0 => 5,
        .pipe1 => 5,
        .pipe2 => 1,
        .pipe3 => 1,
        .pipe4 => 1,
        .pipe5 => 1,
        .tx => 5,
    };

    return self;
}

test "Address.init(.pipe0)" {
    const address = Address.init(.pipe0);
    try testing.expectEqual(
        Pipe.pipe0,
        address.pipe,
    );
    try testing.expectEqual(
        0x0A,
        address.pipe_relative_register,
    );
    try testing.expectEqual(
        5,
        address.pipe_relative_bytes,
    );
}

pub fn register(self: *Address) Register {
    self.reg = .{
        .ptr = self,
        .vtable = .{
            .bytes = self.pipe_relative_bytes,
            .register_index = self.pipe_relative_register,
            .fromRegister = fromRegister,
            .toRegister = toRegister,
        },
    };

    return self.reg;
}

pub fn fromRegister(ctx: *Address, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    ctx.address = data;
}

pub fn toRegister(ctx: Address) ?[]const u8 {
    return ctx.address;
}

pub fn getAddress(self: *Address) ?[]const u8 {
    try self.reg.readRegister(self.reg);
    return self.address;
}

pub fn setAddress(self: *Address, address: []const u8) !void {
    if (address.len != self.pipe_relative_bytes) {
        return error.InvalidValue;
    }
    self.address = address;
    try self.reg.writeRegister();
}

test "Address.setAddress" {
    var address: Address = Address.init(.pipe0);
    try testing.expectEqual(
        null,
        address.address,
    );
    try testing.expectError(
        error.InvalidValue,
        address.setAddress(&.{
            0x01,
            0x02,
            0x03,
            0x04,
            0x05,
            0x06,
        }),
    );
}

pub const Pipe = enum {
    pub fn fromRxPipe(pipe: RxPipe.Pipe) Pipe {
        return switch (pipe) {
            .pipe0 => .pipe0,
            .pipe1 => .pipe1,
            .pipe2 => .pipe2,
            .pipe3 => .pipe3,
            .pipe4 => .pipe4,
            .pipe5 => .pipe5,
        };
    }

    pub fn fromTxPipe() Pipe {
        return .tx;
    }

    pub fn toRxPipe(pipe: Pipe) !RxPipe.Pipe {
        return switch (pipe) {
            .pipe0 => .pipe0,
            .pipe1 => .pipe1,
            .pipe2 => .pipe2,
            .pipe3 => .pipe3,
            .pipe4 => .pipe4,
            .pipe5 => .pipe5,
            .tx => error.InvalidValue,
        };
    }

    pub fn isTxPipe(pipe: Pipe) bool {
        return pipe == .tx;
    }

    pipe0,
    pipe1,
    pipe2,
    pipe3,
    pipe4,
    pipe5,
    tx,
};

test "Address.Pipe.fromRxPipe" {
    try testing.expectEqual(
        Pipe.pipe0,
        Pipe.fromRxPipe(.pipe0),
    );
    try testing.expectEqual(
        Pipe.pipe1,
        Pipe.fromRxPipe(.pipe1),
    );
    try testing.expectEqual(
        Pipe.pipe2,
        Pipe.fromRxPipe(.pipe2),
    );
    try testing.expectEqual(
        Pipe.pipe3,
        Pipe.fromRxPipe(.pipe3),
    );
    try testing.expectEqual(
        Pipe.pipe4,
        Pipe.fromRxPipe(.pipe4),
    );
    try testing.expectEqual(
        Pipe.pipe5,
        Pipe.fromRxPipe(.pipe5),
    );
}

test "Address.Pipe.fromTxPipe" {
    try testing.expectEqual(
        Pipe.tx,
        Pipe.fromTxPipe(),
    );
}

test "Address.Pipe.toRxPipe" {
    try testing.expectEqual(
        RxPipe.Pipe.pipe0,
        try Pipe.toRxPipe(.pipe0),
    );
    try testing.expectEqual(
        RxPipe.Pipe.pipe1,
        try Pipe.toRxPipe(.pipe1),
    );
    try testing.expectEqual(
        RxPipe.Pipe.pipe2,
        try Pipe.toRxPipe(.pipe2),
    );
    try testing.expectEqual(
        RxPipe.Pipe.pipe3,
        try Pipe.toRxPipe(.pipe3),
    );
    try testing.expectEqual(
        RxPipe.Pipe.pipe4,
        try Pipe.toRxPipe(.pipe4),
    );
    try testing.expectEqual(
        RxPipe.Pipe.pipe5,
        try Pipe.toRxPipe(.pipe5),
    );
    try testing.expectError(
        error.InvalidValue,
        Pipe.toRxPipe(.tx),
    );
}

test "Address.Pipe.isTxPipe" {
    try testing.expectEqual(
        false,
        Pipe.isTxPipe(.pipe0),
    );
    try testing.expectEqual(
        false,
        Pipe.isTxPipe(.pipe1),
    );
    try testing.expectEqual(
        false,
        Pipe.isTxPipe(.pipe2),
    );
    try testing.expectEqual(
        false,
        Pipe.isTxPipe(.pipe3),
    );
    try testing.expectEqual(
        false,
        Pipe.isTxPipe(.pipe4),
    );
    try testing.expectEqual(
        false,
        Pipe.isTxPipe(.pipe5),
    );
    try testing.expectEqual(
        true,
        Pipe.isTxPipe(.tx),
    );
}
