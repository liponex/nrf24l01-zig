const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const TxObserve = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x08,
};

reg: *Register = undefined,

packets_lost: u8 = 0,
auto_retransmitted: u8 = 0,

pub fn init() TxObserve {
    return .{};
}

pub fn register(self: *TxObserve) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: TxObserve) !void {
    var tmp = TxObserve.init();
    var tmp_reg = tmp.register();
    tmp.reg = &tmp_reg;
    try tmp.reg.readRegister();

    if (self.packets_lost != tmp.packets_lost) {
        return error.InvalidValue;
    }

    if (self.auto_retransmitted != tmp.auto_retransmitted) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(ctx: *TxObserve, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    ctx.packets_lost = (data[0] & (0b1111 << 4)) >> 4;
    ctx.auto_retransmitted = data[0] & 0b1111;
}

/// This function must not be called, since the register is read-only.
pub fn toRegister(self: TxObserve) ?[]const u8 {
    var data: u8 = 0;
    data |= self.packets_lost << 4;
    data |= self.auto_retransmitted;

    return &.{
        data,
    };
}

pub fn getPacketsLost(self: TxObserve) !u8 {
    try self.reg.readRegister();
    return self.packets_lost;
}

test "TxObserve.getPacketsLost" {
    inline for (0..16) |i| {
        var txObserve = TxObserve.init();
        var mock = MockRegister.init(
            null,
            &.{
                @as(u8, i) << 4,
            },
            1,
            0x08,
            &txObserve,
        );
        var reg = mock.register();
        txObserve.reg = &reg;
        try testing.expectEqual(i, try txObserve.getPacketsLost());
    }
}

pub fn getAutoRetransmitted(self: TxObserve) !u8 {
    try self.reg.readRegister();
    return self.auto_retransmitted;
}

test "TxObserve.getAutoRetransmitted" {
    inline for (0..16) |i| {
        var txObserve = TxObserve.init();
        var mock = MockRegister.init(
            null,
            &.{
                @as(u8, i),
            },
            1,
            0x08,
            &txObserve,
        );
        var reg = mock.register();
        txObserve.reg = &reg;
        try testing.expectEqual(i, try txObserve.getAutoRetransmitted());
    }
}
