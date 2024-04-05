const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const Feature = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x1D,
};

reg: *Register = undefined,

dynamic_payload_length: bool = false,
payload_with_ack: bool = false,
dynamic_ack: bool = false,

pub fn init() Feature {
    return .{};
}

pub fn register(self: *Feature) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: Feature) !void {
    var tmp = Feature.init();
    var tmp_reg = tmp.register();
    tmp.reg = &tmp_reg;
    try tmp.reg.readRegister();

    if (self.dynamic_payload_length != tmp.dynamic_payload_length) {
        return error.InvalidValue;
    }

    if (self.payload_with_ack != tmp.payload_with_ack) {
        return error.InvalidValue;
    }

    if (self.dynamic_ack != tmp.dynamic_ack) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(ctx: *Feature, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    ctx.dynamic_payload_length = (data[0] & (1 << 2)) > 0;
    ctx.payload_with_ack = (data[0] & (1 << 1)) > 0;
    ctx.dynamic_ack = (data[0] & 1) > 0;
}

pub fn toRegister(ctx: Feature) ?[]const u8 {
    var data: u8 = 0;
    data |= @as(u8, @intFromBool(ctx.dynamic_payload_length)) << 2;
    data |= @as(u8, @intFromBool(ctx.payload_with_ack)) << 1;
    data |= @as(u8, @intFromBool(ctx.dynamic_ack));

    return &.{
        data,
    };
}

pub fn getDynamicPayloadLength(self: Feature) bool {
    return self.dynamic_payload_length;
}

/// Enbables/Disables dynamic payload length
pub fn setDynamicPayloadLength(self: *Feature, enable: bool) !void {
    self.dynamic_payload_length = enable;
    try self.reg.writeRegister();
}

test "Feature.setDynamicPayloadLength(true)" {
    var feature = Feature.init();
    feature.dynamic_payload_length = false;
    feature.payload_with_ack = false;
    feature.dynamic_ack = false;

    var mock = MockRegister.init(
        &.{1 << 2},
        null,
        1,
        0x1D,
        &feature,
    );
    var reg = mock.register();
    feature.reg = &reg;

    try feature.setDynamicPayloadLength(true);
    try testing.expectEqual(
        true,
        feature.dynamic_payload_length,
    );
}

test "Feature.setDynamicPayloadLength(false)" {
    var feature = Feature.init();
    feature.dynamic_payload_length = true;
    feature.payload_with_ack = false;
    feature.dynamic_ack = false;

    var mock = MockRegister.init(
        &.{0},
        null,
        1,
        0x1D,
        &feature,
    );
    var reg = mock.register();
    feature.reg = &reg;

    try feature.setDynamicPayloadLength(false);
    try testing.expectEqual(
        false,
        feature.dynamic_payload_length,
    );
}

pub fn getPayloadWithAck(self: Feature) bool {
    return self.payload_with_ack;
}

/// Enables/Disables payload with ack
pub fn setPayloadWithAck(self: *Feature, enable: bool) !void {
    self.payload_with_ack = enable;
    try self.reg.writeRegister();
}

test "Feature.setPayloadWithAck(true)" {
    var feature = Feature.init();
    feature.dynamic_payload_length = false;
    feature.payload_with_ack = false;
    feature.dynamic_ack = false;

    var mock = MockRegister.init(
        &.{1 << 1},
        null,
        1,
        0x1D,
        &feature,
    );
    var reg = mock.register();
    feature.reg = &reg;

    try feature.setPayloadWithAck(true);
    try testing.expectEqual(
        true,
        feature.payload_with_ack,
    );
}

test "Feature.setPayloadWithAck(false)" {
    var feature = Feature.init();
    feature.dynamic_payload_length = false;
    feature.payload_with_ack = true;
    feature.dynamic_ack = false;

    var mock = MockRegister.init(
        &.{0},
        null,
        1,
        0x1D,
        &feature,
    );
    var reg = mock.register();
    feature.reg = &reg;

    try feature.setPayloadWithAck(false);
    try testing.expectEqual(
        false,
        feature.payload_with_ack,
    );
}

pub fn getDynamicAck(self: Feature) bool {
    return self.dynamic_ack;
}

/// Enables/Disables dynamic ack
///
/// When enabled, Writing TX Payload with no Ack `W_TX_PAYLOAD_NOACK`
/// is enabled.
pub fn setDynamicAck(self: *Feature, enable: bool) !void {
    self.dynamic_ack = enable;
    try self.reg.writeRegister();
}

test "Feature.setDynamicAck(true)" {
    var feature = Feature.init();
    feature.dynamic_payload_length = false;
    feature.payload_with_ack = false;
    feature.dynamic_ack = false;

    var mock = MockRegister.init(
        &.{1},
        null,
        1,
        0x1D,
        &feature,
    );
    var reg = mock.register();
    feature.reg = &reg;

    try feature.setDynamicAck(true);
    try testing.expectEqual(
        true,
        feature.dynamic_ack,
    );
}

test "Feature.setDynamicAck(false)" {
    var feature = Feature.init();
    feature.dynamic_payload_length = false;
    feature.payload_with_ack = false;
    feature.dynamic_ack = true;

    var mock = MockRegister.init(
        &.{0},
        null,
        1,
        0x1D,
        &feature,
    );
    var reg = mock.register();
    feature.reg = &reg;

    try feature.setDynamicAck(false);
    try testing.expectEqual(
        false,
        feature.dynamic_ack,
    );
}
