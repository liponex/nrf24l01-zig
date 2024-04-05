const std = @import("std");
const Allocator = std.mem.Allocator;

const log = std.log.scoped(.transceiver);

pub const Config = @import("transceiver/Config.zig");
pub const RxPipe = @import("transceiver/RxPipe.zig");
pub const TxPipe = @import("transceiver/TxPipe.zig");

const Transceiver = @This();

// ceH: *const fn () void,
// ceL: *const fn () void,
// csnH: *const fn () void,
// csnL: *const fn () void,
// llRw: *const fn (u8) u8,

config: *Config = undefined,
rx_pipes: []RxPipe = undefined,
tx_pipe: *TxPipe = undefined,

pub fn init(
    allocator: Allocator,
    config: *Config,
    rx_pipes: []const RxPipe,
    tx_pipe: *TxPipe,
) !Transceiver {
    log.debug("Initializing nRF24L01 configuration with pipes", .{});
    var tc: Transceiver = .{
        .config = config,
    };
    tc.rx_pipes = try allocator.alloc(RxPipe, 6);
    std.mem.zeroInit(RxPipe, tc.rx_pipes);
    for (rx_pipes) |pipe| {
        const pipe_index = switch (pipe.pipe) {
            .pipe0 => 0,
            .pipe1 => 1,
            .pipe2 => 2,
            .pipe3 => 3,
            .pipe4 => 4,
            .pipe5 => 5,
        };
        tc.rx_pipes[pipe_index].main_config = pipe.main_config;
        tc.rx_pipes[pipe_index].pipe = pipe.pipe;
        tc.rx_pipes[pipe_index].auto_acknowlegment = pipe.auto_acknowlegment;
        tc.rx_pipes[pipe_index].dynamic_payload_length = pipe.dynamic_payload_length;
        tc.rx_pipes[pipe_index].address = pipe.address;
        tc.rx_pipes[pipe_index].payload_length = pipe.payload_length;
        tc.rx_pipes[pipe_index].enabled = pipe.enabled;
        tc.rx_pipes[pipe_index].ack_payload = pipe.ack_payload;
    }
    tc.tx_pipe = tx_pipe;
    tc.config = config;
    return tc;
}

pub fn validate(self: *Transceiver) !void {
    try self.config.validate();
}

pub fn check(self: *Transceiver) !void {
    const prev_address = self.tx_pipe.address;
    const prev_width = self.config.address_width.width;

    self.config.address_width.setLength(5);

    const test_address = &.{ 0x01, 0x02, 0x03, 0x04, 0x05 };
    try self.tx_pipe.address.setAddress(test_address);
    if (self.tx_pipe.address.getAddress()) |address| {
        if (!std.mem.eql(u8, test_address, address)) {
            return error.CheckFailed;
        }
    }
    else {
        std.log.err("Address is null!", .{});
        return error.CheckFailed;
    }

    self.config.address_width.setLength(prev_width);
    try self.tx_pipe.address.setAddress(prev_address);
}

pub fn deinit(self: *Transceiver, allocator: Allocator) void {
    allocator.free(self.rx_pipes);
}
