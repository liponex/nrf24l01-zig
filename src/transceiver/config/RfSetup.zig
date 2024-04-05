//! RF transceiver settings Register
//!
//! Specifies the delay between retransmissions and the number of retransmissions.
const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const RfSetup = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x06,
};

reg: *Register = undefined,

continious_wave: bool = false,
pll_lock: bool = false,
data_rate: DataRate = .@"1mbps",
output_power: Power = .@"0dBm",

pub fn init() RfSetup {
    return .{};
}

pub fn register(self: *RfSetup) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: RfSetup) !void {
    var tmp = RfSetup.init();
    var tmp_reg = tmp.register();
    tmp.reg = &tmp_reg;
    try tmp.reg.readRegister();

    if (self.continious_wave != tmp.continious_wave) {
        return error.InvalidValue;
    }

    if (self.pll_lock != tmp.pll_lock) {
        return error.InvalidValue;
    }

    if (self.data_rate != tmp.data_rate) {
        return error.InvalidValue;
    }

    if (self.output_power != tmp.output_power) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(self: *RfSetup, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;
    self.continious_wave = (data[0] & (1 << 7)) > 0;
    self.pll_lock = (data[0] & (1 << 4)) > 0;
    self.data_rate = try DataRate.fromInt(data[0] & ((1 << 5) | (1 << 3)));
    self.output_power = try Power.fromInt(data[0] & (0b11 << 1));
}

pub fn toRegister(self: RfSetup) ?[]const u8 {
    var data: u8 = 0b0000_0000;
    data |= @as(u8, @intFromBool(self.continious_wave)) << 7;
    data |= @as(u8, @intFromBool(self.pll_lock)) << 4;
    data |= self.data_rate.toInt();
    data |= self.output_power.toInt() << 1;
    return &.{
        data,
    };
}

pub fn getContiniousWave(self: RfSetup) bool {
    return self.continious_wave;
}

test "RfSetup.getContiniousWave" {
    var rfSetup = RfSetup.init();

    rfSetup.continious_wave = false;
    try testing.expectEqual(false, rfSetup.getContiniousWave());

    rfSetup.continious_wave = true;
    try testing.expectEqual(true, rfSetup.getContiniousWave());
}

pub fn setContiniousWave(self: *RfSetup, continious_wave: bool) !void {
    self.continious_wave = continious_wave;
    try self.reg.writeRegister();
}

test "RfSetup.setContiniousWave" {
    {
        var rfSetup = RfSetup.init();
        rfSetup.continious_wave = false;

        const test_byte: u8 = 0b1000_0110;

        var mock = MockRegister.init(
            &.{
                test_byte,
            },
            null,
            1,
            0x06,
            &rfSetup,
        );
        var reg = mock.register();
        rfSetup.reg = &reg;

        try rfSetup.setContiniousWave(true);
        try testing.expectEqual(
            true,
            rfSetup.continious_wave,
        );
    }
    {
        var rfSetup = RfSetup.init();
        rfSetup.continious_wave = true;

        const test_byte: u8 = 0b0000_0110;

        var mock = MockRegister.init(
            &.{
                test_byte,
            },
            null,
            1,
            0x06,
            &rfSetup,
        );
        var reg = mock.register();
        rfSetup.reg = &reg;

        try rfSetup.setContiniousWave(false);
        try testing.expectEqual(
            false,
            rfSetup.continious_wave,
        );
    }
}

/// If `true` forces PLL lock signal. Only used in tests.
pub fn getPllLock(self: RfSetup) bool {
    return self.pll_lock;
}

/// If `true` forces PLL lock signal. Only used in tests.
pub fn setPllLock(self: RfSetup, pll_lock: bool) !void {
    self.pll_lock = pll_lock;
    try self.reg.writeRegister();
}

pub fn getDataRate(self: RfSetup) DataRate {
    return self.data_rate;
}

pub fn setDataRate(self: RfSetup, data_rate: DataRate) !void {
    self.delay = data_rate;
    try self.reg.writeRegister();
}

pub fn getOutputPower(self: RfSetup) Power {
    return self.output_power;
}

pub fn setOutputPower(self: RfSetup, output_power: Power) !void {
    self.output_power = output_power;
    try self.reg.writeRegister();
}

/// Data rate of the RF transceiver.
///
/// More speed means less distance.
pub const DataRate = enum {
    pub fn fromInt(val: u8) !DataRate {
        return switch (val) {
            0b00_0000 => .@"1mbps",
            0b00_1000 => .@"2mbps",
            0b10_0000 => .@"250kbps",
            else => return error.InvalidValue,
        };
    }

    pub fn toInt(self: DataRate) u8 {
        return switch (self) {
            .@"1mbps" => 0b0000_0000,
            .@"2mbps" => 0b0000_1000,
            .@"250kbps" => 0b10_0000,
        };
    }

    @"250kbps",
    @"1mbps",
    @"2mbps",
};

/// RF output power in TX mode.
///
/// Less power means less distance, but less power consumption.
pub const Power = enum {
    pub fn fromInt(val: u8) !Power {
        return switch (val) {
            0b00 => .@"-18dBm",
            0b01 => .@"-12dBm",
            0b10 => .@"-6dBm",
            0b11 => .@"0dBm",
            else => return error.InvalidValue,
        };
    }

    pub fn toInt(self: Power) u8 {
        return switch (self) {
            .@"-18dBm" => 0b00,
            .@"-12dBm" => 0b01,
            .@"-6dBm" => 0b10,
            .@"0dBm" => 0b11,
        };
    }

    @"-18dBm",
    @"-12dBm",
    @"-6dBm",
    @"0dBm",
};
