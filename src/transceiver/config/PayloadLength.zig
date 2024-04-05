//! PayloadLength Register
const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");
const RxPipe = @import("../RxPipe.zig");

const PayloadLength = @This();

reg: *Register = undefined,

pipe: RxPipe.Pipe = undefined,
pipe_relative_register: u8 = undefined,

length: u8 = 0,

pub fn init(pipe: RxPipe.Pipe) PayloadLength {
    var self: PayloadLength = .{};
    self.pipe = pipe;
    self.pipe_relative_register = switch (pipe) {
        .pipe0 => 0x11,
        .pipe1 => 0x12,
        .pipe2 => 0x13,
        .pipe3 => 0x14,
        .pipe4 => 0x15,
        .pipe5 => 0x16,
    };

    return self;
}

test "PayloadLength.init(.pipe0)" {
    // TODO: Implement after mocks are done

    // const Config = @import("../Config.zig");
    // var config: Config = Config.init();
    // const pipe = RxPipe.init(.pipe0, &config);
    // const payload_length = init(pipe.pipe);
    // try testing.expectEqual(
    //     RxPipe.Pipe.pipe0,
    //     payload_length.pipe,
    // );
    // try testing.expectEqual(
    //     0x11,
    //     payload_length.pipe_relative_register,
    // );
    // try testing.expectEqual(
    //     0,
    //     payload_length.length,
    // );
}

pub fn register(self: *PayloadLength) Register {
    return Register.init(&RealRegister{
        .bytes = 1,
        .register_index = self.pipe_relative_register,
        .ptr = self,
        .vtable = .{
            .fromRegister = fromRegister,
            .toRegister = toRegister,
        },
    });
}

pub fn fromRegister(self: *PayloadLength, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    self.length = data[0];
}

pub fn toRegister(self: PayloadLength) ?[]const u8 {
    return &.{
        self.length,
    };
}

pub fn getLength(self: *PayloadLength) !u8 {
    try self.reg.readRegister();
    return self.length;
}

test "PayloadLength.getLength" {
    inline for (0..6) |pipe| {
        inline for (0..32) |p_len| {
            const rx_pipe: RxPipe.Pipe = switch (pipe) {
                0 => .pipe0,
                1 => .pipe1,
                2 => .pipe2,
                3 => .pipe3,
                4 => .pipe4,
                5 => .pipe5,
                else => unreachable,
            };
            var payload_length = PayloadLength.init(rx_pipe);
            var mock = MockRegister.init(
                null,
                &.{p_len},
                1,
                payload_length.pipe_relative_register,
                &payload_length,
            );
            var reg = mock.register();
            payload_length.reg = &reg;
            try testing.expectEqual(
                p_len,
                try payload_length.getLength(),
            );
        }
    }
}

pub fn setLength(self: *PayloadLength, length: u8) !void {
    self.length = length;
    try self.reg.writeRegister();
}

test "PayloadLength.setLength" {
    inline for (0..6) |pipe| {
        inline for (0..32) |p_len| {
            const rx_pipe: RxPipe.Pipe = switch (pipe) {
                0 => .pipe0,
                1 => .pipe1,
                2 => .pipe2,
                3 => .pipe3,
                4 => .pipe4,
                5 => .pipe5,
                else => unreachable,
            };
            var payload_length = PayloadLength.init(rx_pipe);
            var mock = MockRegister.init(
                &.{p_len},
                null,
                1,
                payload_length.pipe_relative_register,
                &payload_length,
            );
            var reg = mock.register();
            payload_length.reg = &reg;
            try payload_length.setLength(p_len);
            try testing.expectEqual(
                p_len,
                payload_length.length,
            );
        }
    }
}
