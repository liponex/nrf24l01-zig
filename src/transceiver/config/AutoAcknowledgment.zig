//! Auto Retransmit Register
const std = @import("std");

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const RxPipe = @import("../RxPipe.zig");

const AutoAcknowledgment = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x01,
};

reg: Register = undefined,

pipe0: bool = true,
pipe1: bool = true,
pipe2: bool = true,
pipe3: bool = true,
pipe4: bool = true,
pipe5: bool = true,

pub fn init() AutoAcknowledgment {
    return .{};
}
test {
    var aa = AutoAcknowledgment.init();
    var mock = MockRegister.init(
        &.{0b0011_1111},
        &.{0b0000_0000},
        reg_info.bytes,
        reg_info.index,
        &aa,
    );
    aa.reg = mock.register();

    try aa.reg.writeRegister();
    try aa.reg.readRegister();
}

pub fn register(self: *AutoAcknowledgment) Register {
    return Register.init(&RealRegister.init(
        reg_info.bytes,
        reg_info.index,
        self,
    ));
}

pub fn validate(self: AutoAcknowledgment) !void {
    var tmp = AutoAcknowledgment.init();
    tmp.reg = tmp.register();
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

pub fn fromRegister(ctx: *AutoAcknowledgment, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    ctx.pipe5 = (data[0] & (1 << 5)) > 0;
    ctx.pipe4 = (data[0] & (1 << 4)) > 0;
    ctx.pipe3 = (data[0] & (1 << 3)) > 0;
    ctx.pipe2 = (data[0] & (1 << 2)) > 0;
    ctx.pipe1 = (data[0] & (1 << 1)) > 0;
    ctx.pipe0 = (data[0] & 1) > 0;
}

pub fn toRegister(ctx: AutoAcknowledgment) ?[]const u8 {
    var data: u8 = 0;
    data |= @as(u8, @intFromBool(ctx.pipe5)) << 5;
    data |= @as(u8, @intFromBool(ctx.pipe4)) << 4;
    data |= @as(u8, @intFromBool(ctx.pipe3)) << 3;
    data |= @as(u8, @intFromBool(ctx.pipe2)) << 2;
    data |= @as(u8, @intFromBool(ctx.pipe1)) << 1;
    data |= @as(u8, @intFromBool(ctx.pipe0));

    return &.{
        data,
    };
}

pub fn getAutoAcknowledgment(self: AutoAcknowledgment, pipe: RxPipe.Pipe) bool {
    return switch (pipe) {
        .pipe5 => self.pipe5,
        .pipe4 => self.pipe4,
        .pipe3 => self.pipe3,
        .pipe2 => self.pipe2,
        .pipe1 => self.pipe1,
        .pipe0 => self.pipe0,
    };
}

pub fn setAutoAcknowledgment(
    self: *AutoAcknowledgment,
    pipe: RxPipe.Pipe,
    enable: bool,
) void {
    switch (pipe) {
        .pipe5 => self.pipe5 = enable,
        .pipe4 => self.pipe4 = enable,
        .pipe3 => self.pipe3 = enable,
        .pipe2 => self.pipe2 = enable,
        .pipe1 => self.pipe1 = enable,
        .pipe0 => self.pipe0 = enable,
    }
}
