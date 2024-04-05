//! Auto Retransmit Register
//!
//! Specifies the delay between retransmissions and the number of retransmissions.
const std = @import("std");

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const AutoRetransmit = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x04,
};

reg: Register = undefined,

delay: u4 = 0,
count: u4 = 0,

pub fn init() AutoRetransmit {
    return .{};
}

test {
    var ar = AutoRetransmit.init();
    var mock = MockRegister.init(
            &.{0b0000_0000},
            &.{0b0000_0000},
            1,
            0x04,
            &ar,
    );
    ar.reg = mock.register();

    try ar.reg.writeRegister();
    try ar.reg.readRegister();
}

pub fn register(self: *AutoRetransmit) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: AutoRetransmit) !void {
    var tmp = AutoRetransmit.init();
    tmp.reg = tmp.register();
    try tmp.reg.readRegister();

    if (self.delay != tmp.delay) {
        return error.InvalidValue;
    }

    if (self.count != tmp.count) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(ctx: *AutoRetransmit, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    ctx.delay = @truncate(data[0] >> 4);
    ctx.count = @truncate(data[0] & 0xF);
}

pub fn toRegister(ctx: AutoRetransmit) ?[]const u8 {
    return &.{
        (@as(u8, ctx.delay) << 4) | ctx.count,
    };
}

pub fn getDelay(self: AutoRetransmit) Delay {
    return Delay.fromInt(self.delay);
}

pub fn setDelay(self: AutoRetransmit, delay: Delay) void {
    self.delay = delay;
    try self.reg.writeRegister();
}

pub fn getCount(self: AutoRetransmit) u4 {
    return self.count;
}

pub fn setCount(self: AutoRetransmit, count: u8) !void {
    if (count > 0xF) {
        return error.ValueTooBig;
    }

    self.count = @truncate(count);
    try self.reg.writeRegister();
}

pub const Delay = enum {
    pub fn fromInt(val: u8) !Delay {
        return switch (val) {
            0x0 => .@"250us",
            0x1 => .@"500us",
            0x2 => .@"750us",
            0x3 => .@"1000us",
            0x4 => .@"1250us",
            0x5 => .@"1500us",
            0x6 => .@"1750us",
            0x7 => .@"2000us",
            0x8 => .@"2250us",
            0x9 => .@"2500us",
            0xA => .@"2750us",
            0xB => .@"3000us",
            0xC => .@"3250us",
            0xD => .@"3500us",
            0xE => .@"3750us",
            0xF => .@"4000us",
            else => return error.InvalidValue,
        };
    }

    pub fn toInt(self: Delay) u4 {
        const result = switch (self) {
            .none => 0x0,
            .@"250us" => 0x0,
            .@"500us" => 0x1,
            .@"750us" => 0x2,
            .@"1000us" => 0x3,
            .@"1250us" => 0x4,
            .@"1500us" => 0x5,
            .@"1750us" => 0x6,
            .@"2000us" => 0x7,
            .@"2250us" => 0x8,
            .@"2500us" => 0x9,
            .@"2750us" => 0xA,
            .@"3000us" => 0xB,
            .@"3250us" => 0xC,
            .@"3500us" => 0xD,
            .@"3750us" => 0xE,
            .@"4000us" => 0xF,
        };
        return result;
    }

    none,
    @"250us",
    @"500us",
    @"750us",
    @"1000us",
    @"1250us",
    @"1500us",
    @"1750us",
    @"2000us",
    @"2250us",
    @"2500us",
    @"2750us",
    @"3000us",
    @"3250us",
    @"3500us",
    @"3750us",
    @"4000us",
};
