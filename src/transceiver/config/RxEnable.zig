//! Rx pipes enable Register
const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");
const RxPipe = @import("../RxPipe.zig");

const RxEnable = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x02,
};

reg: *Register = undefined,

pipe0: bool = true,
pipe1: bool = true,
pipe2: bool = false,
pipe3: bool = false,
pipe4: bool = false,
pipe5: bool = false,

pub fn init() RxEnable {
    return .{};
}

pub fn register(self: *RxEnable) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: RxEnable) !void {
    var tmp = RxEnable.init();
    var tmp_reg = tmp.register();
    tmp.reg = &tmp_reg;
    try tmp.reg.readRegister();

    if (self.pipe0 != tmp.pipe0) {
        return error.InvalidValue;
    }

    if (self.pipe1 != tmp.pipe1) {
        return error.InvalidValue;
    }

    if (self.pipe2 != tmp.pipe2) {
        return error.InvalidValue;
    }

    if (self.pipe3 != tmp.pipe3) {
        return error.InvalidValue;
    }

    if (self.pipe4 != tmp.pipe4) {
        return error.InvalidValue;
    }

    if (self.pipe5 != tmp.pipe5) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(self: *RxEnable, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    self.pipe5 = (data[0] & 0b100000) > 0;
    self.pipe4 = (data[0] & 0b010000) > 0;
    self.pipe3 = (data[0] & 0b001000) > 0;
    self.pipe2 = (data[0] & 0b000100) > 0;
    self.pipe1 = (data[0] & 0b000010) > 0;
    self.pipe0 = (data[0] & 0b000001) > 0;
}

pub fn toRegister(self: *RxEnable) ?[]const u8 {
    var data: u8 = 0;
    if (self.pipe5) {
        data |= 0b100000;
    }
    if (self.pipe4) {
        data |= 0b010000;
    }
    if (self.pipe3) {
        data |= 0b001000;
    }
    if (self.pipe2) {
        data |= 0b000100;
    }
    if (self.pipe1) {
        data |= 0b000010;
    }
    if (self.pipe0) {
        data |= 0b000001;
    }

    return &.{
        data,
    };
}

pub fn getPipeStatus(self: *RxEnable, pipe: RxPipe.Pipe) !bool {
    try self.reg.readRegister();
    return switch (pipe) {
        .pipe5 => self.pipe5,
        .pipe4 => self.pipe4,
        .pipe3 => self.pipe3,
        .pipe2 => self.pipe2,
        .pipe1 => self.pipe1,
        .pipe0 => self.pipe0,
    };
}

test "RxEnable.getPipeStatus for one by one" {
    var rxEnable: RxEnable = .{};
    // var reg: Register = undefined;

    inline for (0..6) |i| {
        var mock = MockRegister.init(
            &.{
                0,
            },
            &.{
                @as(u8, 1) << i,
            },
            1,
            0x02,
            &rxEnable,
        );
        var reg = mock.register();
        rxEnable.reg = &reg;
        try testing.expectEqual(i == 0, try rxEnable.getPipeStatus(.pipe0));
        try testing.expectEqual(i == 1, try rxEnable.getPipeStatus(.pipe1));
        try testing.expectEqual(i == 2, try rxEnable.getPipeStatus(.pipe2));
        try testing.expectEqual(i == 3, try rxEnable.getPipeStatus(.pipe3));
        try testing.expectEqual(i == 4, try rxEnable.getPipeStatus(.pipe4));
        try testing.expectEqual(i == 5, try rxEnable.getPipeStatus(.pipe5));
    }
}

test "RxEnable.getPipeStatus all enabled" {
    var rxEnable: RxEnable = .{};
    var mock = MockRegister.init(
        null,
        &.{
            0b00111111,
        },
        1,
        0x02,
        &rxEnable,
    );
    var reg = mock.register();
    rxEnable.reg = &reg;
    try testing.expectEqual(true, rxEnable.getPipeStatus(.pipe0));
    try testing.expectEqual(true, rxEnable.getPipeStatus(.pipe1));
    try testing.expectEqual(true, rxEnable.getPipeStatus(.pipe2));
    try testing.expectEqual(true, rxEnable.getPipeStatus(.pipe3));
    try testing.expectEqual(true, rxEnable.getPipeStatus(.pipe4));
    try testing.expectEqual(true, rxEnable.getPipeStatus(.pipe5));
}

test "RxEnable.getPipeStatus all disabled" {
    var rxEnable: RxEnable = .{};
    var mock = MockRegister.init(
        null,
        &.{
            0b00000000,
        },
        1,
        0x02,
        &rxEnable,
    );
    var reg = mock.register();
    rxEnable.reg = &reg;

    try testing.expectEqual(false, rxEnable.getPipeStatus(.pipe0));
    try testing.expectEqual(false, rxEnable.getPipeStatus(.pipe1));
    try testing.expectEqual(false, rxEnable.getPipeStatus(.pipe2));
    try testing.expectEqual(false, rxEnable.getPipeStatus(.pipe3));
    try testing.expectEqual(false, rxEnable.getPipeStatus(.pipe4));
    try testing.expectEqual(false, rxEnable.getPipeStatus(.pipe5));
}

pub fn setPipeStatus(
    self: *RxEnable,
    pipe: RxPipe.Pipe,
    enable: bool,
) !void {
    switch (pipe) {
        .pipe5 => self.pipe5 = enable,
        .pipe4 => self.pipe4 = enable,
        .pipe3 => self.pipe3 = enable,
        .pipe2 => self.pipe2 = enable,
        .pipe1 => self.pipe1 = enable,
        .pipe0 => self.pipe0 = enable,
    }
    try self.reg.writeRegister();
}

test "RxEnable.setPipeStatus disable all one by one" {
    var rxEnable: RxEnable = .{
        .pipe0 = true,
        .pipe1 = true,
        .pipe2 = true,
        .pipe3 = true,
        .pipe4 = true,
        .pipe5 = true,
    };
    inline for (0..6) |pipe_number| {
        var mock = MockRegister.init(
            &.{
                (@as(u8, 0b00111111) << (pipe_number + 1)) & 0b00111111,
            },
            null,
            1,
            0x02,
            &rxEnable,
        );
        var reg = mock.register();
        rxEnable.reg = &reg;

        switch (pipe_number) {
            0 => try rxEnable.setPipeStatus(.pipe0, false),
            1 => try rxEnable.setPipeStatus(.pipe1, false),
            2 => try rxEnable.setPipeStatus(.pipe2, false),
            3 => try rxEnable.setPipeStatus(.pipe3, false),
            4 => try rxEnable.setPipeStatus(.pipe4, false),
            5 => try rxEnable.setPipeStatus(.pipe5, false),
            else => unreachable,
        }
    }
}

test "RxEnable.setPipeStatus enable all one by one" {
    var rxEnable: RxEnable = .{
        .pipe0 = false,
        .pipe1 = false,
        .pipe2 = false,
        .pipe3 = false,
        .pipe4 = false,
        .pipe5 = false,
    };
    inline for (0..6) |pipe_number| {
        var mock = MockRegister.init(
            &.{
                (@as(u8, 0b00111111) >> (6 - (pipe_number + 1))) & 0b00111111,
            },
            null,
            1,
            0x02,
            &rxEnable,
        );
        var reg = mock.register();
        rxEnable.reg = &reg;

        switch (pipe_number) {
            0 => try rxEnable.setPipeStatus(.pipe0, true),
            1 => try rxEnable.setPipeStatus(.pipe1, true),
            2 => try rxEnable.setPipeStatus(.pipe2, true),
            3 => try rxEnable.setPipeStatus(.pipe3, true),
            4 => try rxEnable.setPipeStatus(.pipe4, true),
            5 => try rxEnable.setPipeStatus(.pipe5, true),
            else => unreachable,
        }
    }
}
