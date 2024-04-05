const Address = @import("config/Address.zig");
const PayloadLength = @import("config/PayloadLength.zig");
const Config = @import("Config.zig");

const TxPipe = @This();

main_config: *Config = undefined,

address: Address = undefined,
payload: ?[]const u8 = null,