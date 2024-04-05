const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const Address = @import("config/Address.zig");
const PayloadLength = @import("config/PayloadLength.zig");
const Config = @import("Config.zig");

const RxPipe = @This();

main_config: *Config = undefined,

pipe: Pipe = undefined,
auto_acknowlegment: bool = true,
dynamic_payload_length: bool = false,
address: Address = undefined,
payload_length: PayloadLength = undefined,
enabled: bool = false,
ack_payload: ?[]const u8 = null,

pub fn init(pipe: Pipe, main_config: *Config) !RxPipe {
    return .{
        .main_config = main_config,
        .pipe = pipe,
        .auto_acknowlegment = main_config.auto_acknowledgment.getAutoAcknowledgment(pipe),
        .dynamic_payload_length = main_config.dynamic_payload_length.getDynamicPayloadLength(pipe),
        .address = Address.init(
            Address.Pipe.fromRxPipe(pipe),
        ),
        .payload_length = PayloadLength.init(pipe),
        .enabled = try main_config.rx_enable.getPipeStatus(pipe),
        .ack_payload = null,
    };
}

test "RxPipe init" {
    // TODO: Implement after mocks are done

    // var main_config = Config.init();
    // const pipe = RxPipe.init(Pipe.pipe0, &main_config);
    // try testing.expectEqual(
    //     Pipe.pipe0,
    //     pipe.pipe,
    // );
    // try testing.expectEqual(
    //     true,
    //     pipe.auto_acknowlegment,
    // );
    // try testing.expectEqual(
    //     false,
    //     pipe.dynamic_payload_length,
    // );
    // try testing.expectEqual(
    //     true,
    //     pipe.enabled,
    // );
    // try testing.expectEqual(
    //     null,
    //     pipe.ack_payload,
    // );
}

pub fn enable(self: *RxPipe) !void {
    if (self.enabled) {
        return;
    }
    self.enabled = true;
    try self.main_config.rx_enable.setPipeStatus(self.pipe, true);
}

test "RxPipe.enable" {
    // TODO: Implement after mocks are done

    // var main_config = Config.init();
    // var pipe = RxPipe.init(Pipe.pipe0, &main_config);
    // pipe.enable();
    //
    // try testing.expectEqual(
    //     true,
    //     pipe.enabled,
    // );
    // try testing.expectEqual(
    //     true,
    //     main_config.rx_enable.pipe0,
    // );
}

pub fn disable(self: *RxPipe) !void {
    if (!self.enabled) {
        return;
    }
    self.enabled = false;
    try self.main_config.rx_enable.setPipeStatus(self.pipe, false);
}

test "RxPipe.disable" {
    // TODO: Implement after mocks are done

    // var main_config = Config.init();
    // var pipe = RxPipe.init(Pipe.pipe0, &main_config);
    // pipe.disable();
    //
    // try testing.expectEqual(
    //     false,
    //     pipe.enabled,
    // );
    // try testing.expectEqual(
    //     false,
    //     main_config.rx_enable.pipe0,
    // );
}

pub fn isEnabled(self: *RxPipe) bool {
    return self.enabled;
}

test "RxPipe.isEnabled" {
    // TODO: Implement after mocks are done

    // var main_config = Config.init();
    // var pipe = RxPipe.init(Pipe.pipe0, &main_config);
    //
    // pipe.enable();
    // try testing.expectEqual(
    //     true,
    //     pipe.enabled,
    // );
    // try testing.expectEqual(
    //     true,
    //     main_config.rx_enable.pipe0,
    // );
    //
    // pipe.disable();
    // try testing.expectEqual(
    //     false,
    //     pipe.enabled,
    // );
    // try testing.expectEqual(
    //     false,
    //     main_config.rx_enable.pipe0,
    // );
    //
    // pipe.enable();
    // try testing.expectEqual(
    //     true,
    //     pipe.enabled,
    // );
    // try testing.expectEqual(
    //     true,
    //     main_config.rx_enable.pipe0,
    // );
}

pub fn setAutoAcknowledgment(self: *RxPipe, auto_acknowlegment: bool) void {
    self.auto_acknowlegment = auto_acknowlegment;
    self.main_config.auto_acknowledgment.setAutoAcknowledgment(self.pipe, auto_acknowlegment);
}

pub fn getAutoAcknowledgment(self: *RxPipe) bool {
    return self.auto_acknowlegment;
}

pub const Pipe = enum {
    pipe0,
    pipe1,
    pipe2,
    pipe3,
    pipe4,
    pipe5,
};
