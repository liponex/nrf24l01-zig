const std = @import("std");
const Allocator = std.mem.Allocator;

const log = std.log.scoped(.transceiver_configuration);

const Self = @This();

const definitions = @import("../definitions.zig");
const Register = @import("Register.zig");

const Config = @import("config/Config.zig");
const AutoAcknowledgment = @import("config/AutoAcknowledgment.zig");
const RxEnable = @import("config/RxEnable.zig");
const AddressWidth = @import("config/AddressWidth.zig");
const AutoRetransmit = @import("config/AutoRetransmit.zig");
const Channel = @import("config/Channel.zig");
const RfSetup = @import("config/RfSetup.zig");
const Status = @import("config/Status.zig");
const TxObserve = @import("config/TxObserve.zig");
const ReceivedPowerDetector = @import("config/ReceivedPowerDetector.zig");
const FifoStatus = @import("config/FifoStatus.zig");
const DynamicPayloadLength = @import("config/DynamicPayloadLength.zig");
const Feature = @import("config/Feature.zig");

config: Config,
auto_acknowledgment: AutoAcknowledgment,
rx_enable: RxEnable,
address_width: AddressWidth,
auto_retransmit: AutoRetransmit,
channel: Channel,
rf_setup: RfSetup,
status: Status,
tx_observe: TxObserve,
received_power_detector: ReceivedPowerDetector,
fifo_status: FifoStatus,
dynamic_payload_length: DynamicPayloadLength,
features: Feature,

pub fn init() Self {
    return .{
        .config = Config.init(),
        .auto_acknowledgment = AutoAcknowledgment.init(),
        .rx_enable = RxEnable.init(),
        .address_width = AddressWidth.init(),
        .auto_retransmit = AutoRetransmit.init(),
        .channel = Channel.init(),
        .rf_setup = RfSetup.init(),
        .status = Status.init(),
        .tx_observe = TxObserve.init(),
        .received_power_detector = ReceivedPowerDetector.init(),
        .fifo_status = FifoStatus.init(),
        .dynamic_payload_length = DynamicPayloadLength.init(),
        .features = Feature.init(),
    };
}

pub fn validate(self: *Self) !void {
    try self.config.validate();
    try self.auto_acknowledgment.validate();
    try self.rx_enable.validate();
    try self.address_width.validate();
    try self.auto_retransmit.validate();
    try self.channel.validate();
    try self.rf_setup.validate();
    try self.status.validate();
    try self.tx_observe.validate();
    try self.received_power_detector.validate();
    try self.fifo_status.validate();
    try self.dynamic_payload_length.validate();
    try self.features.validate();
}
