const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const FifoStatus = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x17,
};

reg: *Register = undefined,

tx_reuse: bool = false,
tx_full: bool = false,
tx_empty: bool = true,
rx_full: bool = false,
rx_empty: bool = true,

pub fn init() FifoStatus {
    return .{};
}

pub fn register(self: *FifoStatus) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: FifoStatus) !void {
    var tmp = FifoStatus.init();
    var tmp_reg = tmp.register();
    tmp.reg = &tmp_reg;
    try tmp.reg.readRegister();

    if (self.tx_reuse != tmp.tx_reuse) {
        return error.InvalidValue;
    }

    if (self.tx_full != tmp.tx_full) {
        return error.InvalidValue;
    }

    if (self.tx_empty != tmp.tx_empty) {
        return error.InvalidValue;
    }

    if (self.rx_full != tmp.rx_full) {
        return error.InvalidValue;
    }

    if (self.rx_empty != tmp.rx_empty) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(self: *FifoStatus, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    self.tx_reuse = (data[0] & (1 << 6)) > 0;
    self.tx_full = (data[0] & (1 << 5)) > 0;
    self.tx_empty = (data[0] & (1 << 4)) > 0;
    self.rx_full = (data[0] & (1 << 1)) > 0;
    self.rx_empty = (data[0] & 1) > 0;
}

/// This function must not be called, since the register is read-only.
pub fn toRegister(self: FifoStatus) ?[]const u8 {
    _ = self;
    unreachable;
}

pub fn getRxFifo(self: *FifoStatus) !Rx {
    try self.reg.readRegister();

    return .{
        .rx_full = self.rx_full,
        .rx_empty = self.rx_empty,
    };
}

test "FifoStatus.getRxFifo" {
    var rx_full: u8 = 0;
    var rx_empty: u8 = 0;
    while (!(rx_full == 1 and rx_empty == 1)) {
        if (rx_full == 0) {
            rx_full = 1;
        } else {
            rx_full = 0;
            rx_empty = 1;
        }

        var fifoStatus = FifoStatus.init();
        fifoStatus.rx_full = false;
        fifoStatus.rx_empty = false;
        fifoStatus.tx_full = false;
        fifoStatus.tx_reuse = false;
        fifoStatus.tx_empty = false;

        var out_byte: u8 = 0;
        out_byte |= rx_full << 1;
        out_byte |= rx_empty;

        var mock = MockRegister.init(
            null,
            &.{out_byte},
            1,
            0x17,
            &fifoStatus,
        );
        var reg = mock.register();
        fifoStatus.reg = &reg;

        const status = try fifoStatus.getRxFifo();
        try testing.expectEqual(
            rx_full > 0,
            status.rx_full,
        );
        try testing.expectEqual(
            rx_empty > 0,
            status.rx_empty,
        );
    }
}

pub fn getTxFifo(self: *FifoStatus) !Tx {
    try self.reg.readRegister();

    return .{
        .tx_reuse = self.tx_reuse,
        .tx_full = self.tx_full,
        .tx_empty = self.tx_empty,
    };
}

test "FifoStatus.getTxFifo" {
    var tx_reuse: u8 = 0;
    var tx_full: u8 = 0;
    var tx_empty: u8 = 0;
    while (!(tx_full == 1 and tx_reuse == 1 and tx_empty == 1)) {
        if (tx_full == 0) {
            tx_full = 1;
        } else if (tx_reuse == 0) {
            tx_full = 0;
            tx_reuse = 1;
        } else {
            tx_reuse = 0;
            tx_empty = 1;
        }

        var fifoStatus = FifoStatus.init();
        fifoStatus.rx_full = false;
        fifoStatus.rx_empty = false;
        fifoStatus.tx_reuse = false;
        fifoStatus.tx_full = false;
        fifoStatus.tx_empty = false;

        var out_byte: u8 = 0;
        out_byte |= tx_reuse << 6;
        out_byte |= tx_full << 5;
        out_byte |= tx_empty << 4;

        var mock = MockRegister.init(
            null,
            &.{out_byte},
            1,
            0x17,
            &fifoStatus,
        );
        var reg = mock.register();
        fifoStatus.reg = &reg;

        const status = try fifoStatus.getTxFifo();
        try testing.expectEqual(
            tx_full > 0,
            status.tx_full,
        );
        try testing.expectEqual(
            tx_empty > 0,
            status.tx_empty,
        );
        try testing.expectEqual(
            tx_reuse > 0,
            status.tx_reuse,
        );
    }
}

/// Struct representing status of the RX FIFO.
pub const Rx = struct {
    /// true - RX FIFO is full
    ///
    /// false - RX FIFO has available space for packets
    rx_full: bool = false,

    /// true - RX FIFO is empty
    ///
    /// false - RX FIFO has packets
    rx_empty: bool = true,
};

/// Struct representing status of the TX FIFO.
pub const Tx = struct {
    /// true - Will send the same packet again and again,
    /// until new payload is send or flush of tx.
    ///
    /// false = Will send the packet only once.
    tx_reuse: bool = false,

    /// true - TX FIFO is full
    ///
    /// false - TX FIFO has available space for packets
    tx_full: bool = false,

    /// true - TX FIFO is empty
    ///
    /// false - TX FIFO has packets
    tx_empty: bool = true,
};
