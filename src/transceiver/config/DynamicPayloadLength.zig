const std = @import("std");
const testing = std.testing;

const MockRegister = @import("../../mock/transceiver/MockRegister.zig");
const RealRegister = @import("../RealRegister.zig");
const Register = @import("../Register.zig");

const RxPipe = @import("../RxPipe.zig");

const DynamicPayloadLength = @This();

const reg_info = Register.Info{
    .bytes = 1,
    .index = 0x1C,
};

reg: *Register = undefined,

pipe0: bool = false,
pipe1: bool = false,
pipe2: bool = false,
pipe3: bool = false,
pipe4: bool = false,
pipe5: bool = false,

pub fn init() DynamicPayloadLength {
    return .{};
}

pub fn register(self: *DynamicPayloadLength) Register {
    return Register.init(&RealRegister.init(
            reg_info.bytes,
            reg_info.index,
            self,
    ));
}

pub fn validate(self: DynamicPayloadLength) !void {
    var tmp = DynamicPayloadLength.init();
    var tmp_reg = tmp.register();
    tmp.reg = &tmp_reg;
    try tmp.reg.readRegister();

    if (self.pipe0 != tmp.pipe0) {
        return error.InvalidValue;
    }

    if (self.pipe1 != tmp.pipe1) {
        return error.InvalidValue;
    }

    if (self.pipe2 != tmp.pipe2) {
        return error.InvalidValue;
    }

    if (self.pipe3 != tmp.pipe3) {
        return error.InvalidValue;
    }

    if (self.pipe4 != tmp.pipe4) {
        return error.InvalidValue;
    }

    if (self.pipe5 != tmp.pipe5) {
        return error.InvalidValue;
    }
}

pub fn fromRegister(self: *DynamicPayloadLength, opt_data: ?[]const u8) !void {
    if (opt_data == null or opt_data.?.len == 0) {
        return error.NoData;
    }

    const data = opt_data.?;

    self.pipe5 = (data[0] & (1 << 5)) > 0;
    self.pipe4 = (data[0] & (1 << 4)) > 0;
    self.pipe3 = (data[0] & (1 << 3)) > 0;
    self.pipe2 = (data[0] & (1 << 2)) > 0;
    self.pipe1 = (data[0] & (1 << 1)) > 0;
    self.pipe0 = (data[0] & 1) > 0;
}

pub fn toRegister(self: DynamicPayloadLength) ?[]const u8 {
    var data: u8 = 0;
    data |= @as(u8, @intFromBool(self.pipe5)) << 5;
    data |= @as(u8, @intFromBool(self.pipe4)) << 4;
    data |= @as(u8, @intFromBool(self.pipe3)) << 3;
    data |= @as(u8, @intFromBool(self.pipe2)) << 2;
    data |= @as(u8, @intFromBool(self.pipe1)) << 1;
    data |= @as(u8, @intFromBool(self.pipe0));

    return &.{data};
}

pub fn getDynamicPayloadLength(self: DynamicPayloadLength, pipe: RxPipe.Pipe) bool {
    return switch (pipe) {
        .pipe5 => self.pipe5,
        .pipe4 => self.pipe4,
        .pipe3 => self.pipe3,
        .pipe2 => self.pipe2,
        .pipe1 => self.pipe1,
        .pipe0 => self.pipe0,
    };
}

test "DynamicPayloadLength.getDynamicPayloadLength" {
    var dpl = DynamicPayloadLength.init();
    dpl.pipe0 = false;
    dpl.pipe1 = false;
    dpl.pipe2 = false;
    dpl.pipe3 = false;
    dpl.pipe4 = false;
    dpl.pipe5 = false;

    try testing.expectEqual(
        false,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe0),
    );
    try testing.expectEqual(
        false,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe1),
    );
    try testing.expectEqual(
        false,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe2),
    );
    try testing.expectEqual(
        false,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe3),
    );
    try testing.expectEqual(
        false,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe4),
    );
    try testing.expectEqual(
        false,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe5),
    );

    dpl.pipe0 = true;
    dpl.pipe1 = true;
    dpl.pipe2 = true;
    dpl.pipe3 = true;
    dpl.pipe4 = true;
    dpl.pipe5 = true;

    try testing.expectEqual(
        true,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe0),
    );
    try testing.expectEqual(
        true,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe1),
    );
    try testing.expectEqual(
        true,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe2),
    );
    try testing.expectEqual(
        true,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe3),
    );
    try testing.expectEqual(
        true,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe4),
    );
    try testing.expectEqual(
        true,
        dpl.getDynamicPayloadLength(RxPipe.Pipe.pipe5),
    );
}

pub fn setDynamicPayloadLength(
    self: *DynamicPayloadLength,
    pipe: RxPipe.Pipe,
    enable: bool,
) !void {
    switch (pipe) {
        .pipe5 => self.pipe5 = enable,
        .pipe4 => self.pipe4 = enable,
        .pipe3 => self.pipe3 = enable,
        .pipe2 => self.pipe2 = enable,
        .pipe1 => self.pipe1 = enable,
        .pipe0 => self.pipe0 = enable,
    }

    try self.reg.writeRegister();
}

test "DynamicPayloadLength.setDynamicPayloadLength" {
    inline for (0..6) |pipe_num| {
        var dpl = DynamicPayloadLength.init();
        dpl.pipe0 = false;
        dpl.pipe1 = false;
        dpl.pipe2 = false;
        dpl.pipe3 = false;
        dpl.pipe4 = false;
        dpl.pipe5 = false;

        const pipe = switch (pipe_num) {
            0 => RxPipe.Pipe.pipe0,
            1 => RxPipe.Pipe.pipe1,
            2 => RxPipe.Pipe.pipe2,
            3 => RxPipe.Pipe.pipe3,
            4 => RxPipe.Pipe.pipe4,
            5 => RxPipe.Pipe.pipe5,
            else => unreachable,
        };

        var mock = MockRegister.init(
            &.{
                @as(u8, 1) << pipe_num,
            },
            null,
            1,
            0x1C,
            &dpl,
        );
        var mock_reg = mock.register();
        dpl.reg = &mock_reg;
        try dpl.setDynamicPayloadLength(pipe, true);
        try testing.expectEqual(
            true,
            switch (pipe_num) {
                0 => dpl.pipe0,
                1 => dpl.pipe1,
                2 => dpl.pipe2,
                3 => dpl.pipe3,
                4 => dpl.pipe4,
                5 => dpl.pipe5,
                else => unreachable,
            },
        );
    }
}
