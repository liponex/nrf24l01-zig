const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const RxPipe = @import("../RxPipe.zig");

const Status = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x07,
};

reg: *Register = undefined,

rx_data_ready: bool = false,
rx_pipe: ?RxPipe.Pipe = null,

tx_data_sent: bool = false,
tx_max_retransmits: bool = false,
tx_full: bool = false,

pub fn init() Status {
    return .{};
}

pub fn register(self: *Status) Register {
    return Register.init(&RealRegister.init(
        reg_info.bytes,
        reg_info.index,
        self,
    ));
}

pub fn validate(self: Status) !void {
    var tmp = Status.init();
    var tmp_reg = tmp.register();
    tmp.reg = &tmp_reg;
    try tmp.reg.readRegister();

    if (self.rx_data_ready != tmp.rx_data_ready) {
        return error.InvalidValue;
    }

    if (self.rx_pipe != tmp.rx_pipe) {
        return error.InvalidValue;
    }

    if (self.tx_data_sent != tmp.tx_data_sent) {
        return error.InvalidValue;
    }

    if (self.tx_max_retransmits != tmp.tx_max_retransmits) {
        return error.InvalidValue;
    }

    if (self.tx_full != tmp.tx_full) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(self: *Status, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    self.rx_data_ready = (data[0] & (1 << 6)) > 0;
    self.tx_data_sent = (data[0] & (1 << 5)) > 0;
    self.tx_max_retransmits = (data[0] & (1 << 4)) > 0;
    self.rx_pipe = switch ((data[0] & (0b111 << 1)) >> 1) {
        0b000 => RxPipe.Pipe.pipe0,
        0b001 => RxPipe.Pipe.pipe1,
        0b010 => RxPipe.Pipe.pipe2,
        0b011 => RxPipe.Pipe.pipe3,
        0b100 => RxPipe.Pipe.pipe4,
        0b101 => RxPipe.Pipe.pipe5,
        0b110, 0b111 => null,
        else => unreachable,
    };
    self.tx_full = (data[0] & 1) > 0;
}

/// This function must be called only to clear
/// `rx_data_ready`, `tx_data_sent` and `tx_max_retransmits`.
pub fn toRegister(self: Status) ?[]const u8 {
    _ = self;
    var data: u8 = 0;
    data |= 1 << 6; // clear rx_data_ready
    data |= 1 << 5; // clear tx_data_sent
    data |= 1 << 4; // clear tx_max_retransmits

    return &.{
        data,
    };
}

pub fn getRxStatus(self: *Status) !Rx {
    try self.reg.readRegister();

    return .{
        .rx_data_ready = self.rx_data_ready,
        .rx_pipe = self.rx_pipe,
    };
}

test "Status.getRxStatus" {
    inline for (0..2) |data_ready| {
        inline for (0..8) |rx_pipe| {
            var status = Status.init();
            var mock = MockRegister.init(
                null,
                &.{
                    (@as(u8, data_ready) << 6) | (@as(u8, rx_pipe) << 1),
                },
                1,
                0x07,
                &status,
            );
            var reg = mock.register();
            status.reg = &reg;
            const rx_status = try status.getRxStatus();
            try testing.expectEqual(
                data_ready > 0,
                rx_status.rx_data_ready,
            );
            try testing.expectEqual(
                switch (rx_pipe) {
                    0 => RxPipe.Pipe.pipe0,
                    1 => RxPipe.Pipe.pipe1,
                    2 => RxPipe.Pipe.pipe2,
                    3 => RxPipe.Pipe.pipe3,
                    4 => RxPipe.Pipe.pipe4,
                    5 => RxPipe.Pipe.pipe5,
                    else => null,
                },
                rx_status.rx_pipe,
            );
        }
    }
}

pub fn getTxStatus(self: *Status) !Tx {
    try self.reg.readRegister();

    return .{
        .tx_data_sent = self.tx_data_sent,
        .tx_max_retransmits = self.tx_max_retransmits,
        .tx_full = self.tx_full,
    };
}

test "Status.getTxStatus" {
    inline for (0..2) |tx_data_sent| {
        inline for (0..2) |tx_max_retransmits| {
            inline for (0..2) |tx_full| {
                var status = Status.init();
                var mock = MockRegister.init(
                    null,
                    &.{
                        (@as(u8, tx_data_sent) << 5) |
                            (@as(u8, tx_max_retransmits) << 4) |
                            (@as(u8, tx_full) << 0),
                    },
                    1,
                    0x07,
                    &status,
                );
                var reg = mock.register();
                status.reg = &reg;
                const tx_status = try status.getTxStatus();
                try testing.expectEqual(
                    tx_data_sent > 0,
                    tx_status.tx_data_sent,
                );
                try testing.expectEqual(
                    tx_max_retransmits > 0,
                    tx_status.tx_max_retransmits,
                );
                try testing.expectEqual(
                    tx_full > 0,
                    tx_status.tx_full,
                );
            }
        }
    }
}

pub fn clearStatus(self: *Status) void {
    self.reg.writeRegister();
    self.reg.readRegister();
}

pub const Rx = struct {
    rx_data_ready: bool = false,
    rx_pipe: ?RxPipe.Pipe = null,
};

pub const Tx = struct {
    tx_data_sent: bool = false,
    tx_max_retransmits: bool = false,
    tx_full: bool = false,
};
