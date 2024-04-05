//! PayloadLength Register
const std = @import("std");

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const RxPipe = @import("../RxPipe.zig");

const AdderssWidth = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x03,
};

reg: Register = undefined,

width: u8 = 0,

pub fn init() AdderssWidth {
    return .{};
}

test {
    var aw = AdderssWidth.init();
    var mock = MockRegister.init(
            &.{0b0000_0000},
            &.{0b0000_0000},
            1,
            0x03,
            &aw,
    );
    aw.reg = mock.register();

    try aw.reg.writeRegister();
    try aw.reg.readRegister();
}

pub fn register(self: *AdderssWidth) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: AdderssWidth) !void {
    var tmp = AdderssWidth.init();
    tmp.reg = tmp.register();
    try tmp.reg.readRegister();

    if (self.width != tmp.width) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(ctx: *AdderssWidth, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    if (data[0] > 0b11) {
        return error.InvalidValue;
    }
    ctx.width = data[0];
}

pub fn toRegister(ctx: AdderssWidth) ?[]const u8 {
    return &.{
        ctx.width,
    };
}

pub fn getLength(self: *AdderssWidth) u8 {
    try self.reg.readRegister();
    return self.length;
}

pub fn setLength(self: *AdderssWidth, width: u8) void {
    self.width = width;
    try self.reg.writeRegister();
}
