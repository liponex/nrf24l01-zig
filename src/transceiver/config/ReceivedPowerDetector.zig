const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const ReceivedPowerDetector = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x09,
};

reg: *Register = undefined,

received_power_detector: bool = false,

pub fn init() ReceivedPowerDetector {
    return .{};
}

pub fn register(self: *ReceivedPowerDetector) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: ReceivedPowerDetector) !void {
    var tmp = ReceivedPowerDetector.init();
    var tmp_reg = tmp.register();
    tmp.reg = &tmp_reg;
    try tmp.reg.readRegister();

    if (self.received_power_detector != tmp.received_power_detector) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(self: *ReceivedPowerDetector, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    self.received_power_detector = (data[0] & 1) > 0;
}

/// This function must not be called, since the register is read-only.
pub fn toRegister(self: ReceivedPowerDetector) ?[]const u8 {
    _ = self;
    unreachable;
}

pub fn getReceivedPowerDetector(self: ReceivedPowerDetector) !bool {
    try self.reg.readRegister();
    return self.received_power_detector;
}

test "ReceivedPowerDetector.getReceivedPowerDetector" {
    inline for (0..2) |i| {
        var rpd = ReceivedPowerDetector.init();
        var mock = MockRegister.init(
            null,
            &.{i},
            1,
            0x09,
            &rpd,
        );
        var reg = mock.register();
        rpd.reg = &reg;

        try testing.expectEqual(
            i > 0,
            try rpd.getReceivedPowerDetector(),
        );
    }
}
