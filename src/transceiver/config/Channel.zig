//! RF Channel Register
const std = @import("std");

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const RxPipe = @import("../RxPipe.zig");

const Channel = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x05,
};

reg: Register = undefined,

channel: u8 = 0,

pub fn init() Channel {
    return .{};
}

pub fn register(self: *Channel) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

test {
    var channel = Channel.init();
    var mock = MockRegister.init(
        &.{0b0000_0000},
        &.{0b0000_0000},
        1,
        0x05,
        &channel,
    );
    channel.reg = mock.register();

    try channel.reg.writeRegister();
    try channel.reg.readRegister();
}

pub fn validate(self: Channel) !void {
    var tmp = Channel.init();
    tmp.reg = tmp.register();
    try tmp.reg.readRegister();

    if (self.channel != tmp.channel) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(ctx: *Channel, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    if (data[0] > 127) {
        return error.InvalidValue;
    }
    ctx.channel = data[0];
}

pub fn toRegister(ctx: Channel) ?[]const u8 {
    return &.{
        ctx.channel,
    };
}

pub fn getChannel(self: *Channel) u8 {
    return self.channel;
}

pub fn setChannel(self: *Channel, channel: u8) void {
    self.channel = channel;
    try self.reg.writeRegister();
}
