//! Config Register
//!
//! Main transceiver configuration.
const std = @import("std");
const assert = std.debug.assert;
const Type = std.builtin.Type;
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const Config = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x00,
};

reg: Register = undefined,

reflect_rx_data_received_on_irq_pin: bool = false,
reflect_tx_data_sent_on_irq_pin: bool = false,
reflect_max_retransmit_on_irq_pin: bool = false,
crc: Crc = .@"1byte",
power: Power = .off,
operational_mode: Mode = .tx,

pub fn init() Config {
    return .{};
}

pub fn register(self: *Config) void {
    self.reg = Register.init(&RealRegister.init(
        reg_info.bytes,
        reg_info.index,
        self,
    ));
}

pub fn validate(self: Config) !void {
    var tmp = Config.init();
    tmp.register();
    try tmp.reg.readRegister();

    if (self.reflect_rx_data_received_on_irq_pin != tmp.reflect_rx_data_received_on_irq_pin) {
        return error.InvalidValue;
    }

    if (self.reflect_tx_data_sent_on_irq_pin != tmp.reflect_tx_data_sent_on_irq_pin) {
        return error.InvalidValue;
    }

    if (self.reflect_max_retransmit_on_irq_pin != tmp.reflect_max_retransmit_on_irq_pin) {
        return error.InvalidValue;
    }

    if (self.crc != tmp.crc) {
        return error.InvalidValue;
    }

    if (self.power != tmp.power) {
        return error.InvalidValue;
    }

    if (self.operational_mode != tmp.operational_mode) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(self: *Config, data: []const u8) !void {
    // const Ptr = @TypeOf(ptr.*);
    // const PtrInfo = @typeInfo(Ptr);
    // assert(PtrInfo == .Pointer); // Must be a pointer
    // assert(PtrInfo.Pointer.size == .One); // Must be a single-item pointer
    // assert(@typeInfo(PtrInfo.Pointer.child) == .Struct); // Must point to a struct
    // const alignment = PtrInfo.Pointer.alignment;
    // const self: Ptr align(alignment) = @ptrCast(@alignCast(ptr));

    if (data.len == 0) {
        return error.NoData;
    }

    self.reflect_rx_data_received_on_irq_pin = (data[0] & (1 << 6)) > 0;
    self.reflect_tx_data_sent_on_irq_pin = (data[0] & (1 << 5)) > 0;
    self.reflect_max_retransmit_on_irq_pin = (data[0] & (1 << 4)) > 0;
    self.crc = try Crc.fromInt((data[0] & (0b11 << 2)) >> 2);
    self.power = try Power.fromInt(data[0] & (1 << 1));
    self.operational_mode = try Mode.fromInt(data[0] & 1);
}

pub fn toRegister(self: Config) ?[]const u8 {
    var data: u8 = 0;

    data |= @as(u8, @intFromBool(self.reflect_rx_data_received_on_irq_pin)) << 6;
    data |= @as(u8, @intFromBool(self.reflect_tx_data_sent_on_irq_pin)) << 5;
    data |= @as(u8, @intFromBool(self.reflect_max_retransmit_on_irq_pin)) << 4;
    data |= @as(u8, Crc.toInt(self.crc)) << 2;
    data |= @as(u8, Power.toInt(self.power)) << 1;
    data |= @as(u8, Mode.toInt(self.operational_mode)) << 0;

    return &.{data};
}

pub fn getReflexRxDataReceived(self: *Config) !bool {
    try self.reg.readRegister();
    return self.reflect_rx_data_received_on_irq_pin;
}

test "Config.getReflexRxDataReceived" {
    var config = Config.init();
    var mock = MockRegister.init(
        null,
        &.{0b0000_0000},
        reg_info.bytes,
        reg_info.index,
        &config,
    );
    config.reg = mock.register();

    try testing.expectEqual(
        false,
        try config.getReflexRxDataReceived(),
    );

    mock = MockRegister.init(
        null,
        &.{0b0100_0000},
        reg_info.bytes,
        reg_info.index,
        &config,
    );
    config.reg = mock.register();

    try testing.expectEqual(
        true,
        try config.getReflexRxDataReceived(),
    );
}

pub fn setReflexRxDataReceived(self: *Config, reflex: bool) !void {
    self.reflect_rx_data_received_on_irq_pin = reflex;
    try self.reg.writeRegister();
}

pub fn getReflexTxDataSent(self: Config) bool {
    return self.reflect_tx_data_sent_on_irq_pin;
}

pub fn setReflexTxDataSent(self: *Config, reflex: bool) void {
    self.reflect_tx_data_sent_on_irq_pin = reflex;
    try self.reg.writeRegister();
}

pub fn getReflexMaxRetransmit(self: Config) bool {
    return self.reflect_max_retransmit_on_irq_pin;
}

pub fn setReflexMaxRetransmit(self: *Config, reflex: bool) void {
    self.reflect_max_retransmit_on_irq_pin = reflex;
    try self.reg.writeRegister();
}

pub fn getCrc(self: Config) Crc {
    return self.crc;
}

pub fn setCrc(self: *Config, crc: Crc) void {
    self.crc = crc;
    try self.reg.writeRegister();
}

pub fn getPower(self: Config) Power {
    return self.power;
}

pub fn setPower(self: *Config, power: Power) void {
    self.power = power;
    self.reg.writeRegister();
}

pub fn getMode(self: Config) Mode {
    return self.operational_mode;
}

pub fn setMode(self: *Config, mode: Mode) void {
    self.operational_mode = mode;
    self.reg.writeRegister();
}

pub const Crc = enum {
    pub fn fromInt(val: u8) !Crc {
        return switch (val) {
            0b00, 0b01 => .off,
            0b10 => .@"1byte",
            0b11 => .@"2bytes",
            else => return error.InvalidValue,
        };
    }

    pub fn toInt(self: Crc) u2 {
        const result: u2 = switch (self) {
            .off => 0b00,
            .@"1byte" => 0b10,
            .@"2bytes" => 0b11,
        };
        return result;
    }

    off,
    @"1byte",
    @"2bytes",
};

pub const Power = enum {
    pub fn fromInt(val: u8) !Power {
        return switch (val) {
            0b0 => .off,
            0b1 => .on,
            else => return error.InvalidValue,
        };
    }

    pub fn toInt(self: Power) u1 {
        return switch (self) {
            .off => 0b0,
            .on => 0b1,
        };
    }

    on,
    off,
};

pub const Mode = enum {
    pub fn fromInt(val: u8) !Mode {
        return switch (val) {
            0b00 => .tx,
            0b01 => .rx,
            else => return error.InvalidValue,
        };
    }

    pub fn toInt(self: Mode) u1 {
        return switch (self) {
            .tx => 0b1,
            .rx => 0b1,
        };
    }

    rx,
    tx,
};
