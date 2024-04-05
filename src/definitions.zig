/// Fake address to test transceiver presence (5 bytes long)
pub const testAddr: []const u8 = "nRF24";

/// Instruction definitions
pub const Cmd = struct {
    /// Register read
    pub const r_register: u8 = 0b0000_0000;

    /// Register write
    pub const w_register: u8 = 0b0010_0000;

    /// (De)Activates R_RX_PL_WID, W_ACK_PAYLOAD, W_TX_PAYLOAD_NOACK features
    pub const activate: u8 = 0b0101_0000;

    /// Read RX-payload width for the top R_RX_PAYLOAD in the RX FIFO.
    pub const r_rx_pl_wid: u8 = 0x60;

    /// Read RX payload
    pub const r_rx_payload: u8 = 0b0110_0001;

    /// Write TX payload
    pub const w_tx_payload: u8 = 0b1010_0000;

    /// Write ACK payload
    pub const w_ack_payload: u8 = 0xA8;

    /// Write TX payload and disable AUTOACK
    pub const w_tx_payload_noack: u8 = 0xB0;

    /// Flush TX FIFO
    pub const flush_tx: u8 = 0xE1;

    /// Flush RX FIFO
    pub const flush_rx: u8 = 0xE2;

    /// Reuse TX payload
    pub const reuse_tx_pl: u8 = 0xE3;

    /// Lock/unlock exclusive features
    pub const lock_unlock: u8 = 0x50;

    /// No operation (used for reading status register)
    pub const nop: u8 = 0b1111_1111;
};

/// Register definitions
pub const Reg = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    /// Configuration register
    config = 0x00,

    /// Enable "Auto acknowledgment"
    en_aa = 0x01,

    /// Enable RX addresses
    en_rx_addr = 0x02,

    /// Setup of address widths
    setup_aw = 0x03,

    /// Setup of automatic retransmit
    setup_retr = 0x04,

    /// RF channel
    rf_ch = 0x05,

    /// RF setup register
    rf_setup = 0x06,

    /// Status register
    status = 0x07,

    /// Transmit observe register
    observe_tx = 0x08,

    /// Received power detector
    rpd = 0x09,

    /// Receive address data pipe 0
    rx_addr_p0 = 0x0A,

    /// Receive address data pipe 1
    rx_addr_p1 = 0x0B,

    /// Receive address data pipe 2
    rx_addr_p2 = 0x0C,

    /// Receive address data pipe 3
    rx_addr_p3 = 0x0D,

    /// Receive address data pipe 4
    rx_addr_p4 = 0x0E,

    /// Receive address data pipe 5
    rx_addr_p5 = 0x0F,

    /// Transmit address
    tx_addr = 0x10,

    /// Number of bytes in RX payload in data pipe 0
    rx_pw_p0 = 0x11,

    /// Number of bytes in RX payload in data pipe 1
    rx_pw_p1 = 0x12,

    /// Number of bytes in RX payload in data pipe 2
    rx_pw_p2 = 0x13,

    /// Number of bytes in RX payload in data pipe 3
    rx_pw_p3 = 0x14,

    /// Number of bytes in RX payload in data pipe 4
    rx_pw_p4 = 0x15,

    /// Number of bytes in RX payload in data pipe 5
    rx_pw_p5 = 0x16,

    /// FIFO status register
    fifo_status = 0x17,

    /// Enable dynamic payload length
    dynpd = 0x1C,

    /// Feature register
    feature = 0x1D,
};

/// Register config bit definitions
pub const Config = struct {
    /// PRIM_RX bit in CONFIG register
    pub const prim_rx: u8 = 0x01;

    /// PWR_UP bit in CONFIG register
    pub const pwr_up: u8 = 0x02;
};

/// Register feature bit definitions
pub const Feature = struct {
    /// EN_DYN_ACK bit in FEATURE register
    pub const en_dyn_ack: u8 = 0b001;

    /// EN_ACK_PAY bit in FEATURE register
    pub const en_ack_pay: u8 = 0b010;

    /// EN_DPL bit in FEATURE register
    pub const en_dpl: u8 = 0b100;
};

/// Register flag bit definitions
pub const Flag = struct {
    /// RX_DR bit (data ready RX FIFO interrupt)
    pub const rx_dr: u8 = 0x40;

    /// TX_DS bit (data sent TX FIFO interrupt)
    pub const tx_ds: u8 = 0x20;

    /// MAX_RT bit (maximum number of TX retransmits interrupt)
    pub const max_rt: u8 = 0x10;
};

/// Register mask definitions
pub const Mask = struct {
    /// Mask bits[4:0] for CMD_RREG and CMD_WREG commands
    pub const reg_map: u8 = 0x1F;

    /// Mask for CRC bits [3:2] in CONFIG register
    pub const crc: u8 = 0x0C;

    /// Mask for all IRQ bits in STATUS register
    pub const status_irq: u8 = 0x70;

    /// Mask RF_PWR[2:1] bits in RF_SETUP register
    pub const rf_pwr: u8 = 0x06;

    /// Mask RX_P_NO[3:1] bits in STATUS register
    pub const rx_p_no: u8 = 0x0E;

    /// Mask RD_DR_[5,3] bits in RF_SETUP register
    pub const datarate: u8 = 0x28;

    /// Mask ERX_P[5:0] bits in EN_RXADDR register
    pub const en_rx: u8 = 0x3F;

    /// Mask [5:0] bits in RX_PW_Px register
    pub const rx_pw: u8 = 0x3F;

    /// Mask for ARD[7:4] bits in SETUP_RETR register
    pub const retr_ard: u8 = 0xF0;

    /// Mask for ARC[3:0] bits in SETUP_RETR register
    pub const retr_arc: u8 = 0x0F;

    /// Mask for RX FIFO status bits [1:0] in FIFO_STATUS register
    pub const rx_fifo: u8 = 0x03;

    /// Mask for TX FIFO status bits [5:4] in FIFO_STATUS register
    pub const tx_fifo: u8 = 0x30;

    /// Mask for PLOS_CNT[7:4] bits in OBSERVE_TX register
    pub const plos_cnt: u8 = 0xF0;

    /// Mask for ARC_CNT[3:0] bits in OBSERVE_TX register
    pub const arc_cnt: u8 = 0x0F;
};

/// Retransmit delay
pub const Ard = enum(u4) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u4 {
        return @intFromEnum(self);
    }

    // none = 0x00,
    us250 = 0x0,
    us500 = 0x1,
    us750 = 0x2,
    us1000 = 0x3,
    us1250 = 0x4,
    us1500 = 0x5,
    us1750 = 0x6,
    us2000 = 0x7,
    us2250 = 0x8,
    us2500 = 0x9,
    us2750 = 0xA,
    us3000 = 0xB,
    us3250 = 0xC,
    us3500 = 0xD,
    us3750 = 0xE,
    us4000 = 0xF,
};

/// Data rate
pub const Dr = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    /// 250 kbps data rate
    kbps250 = 0x20,

    /// 1 Mbps data rate
    mbps1 = 0x00,

    /// 2 Mbps data rate
    mbps2 = 0x08,
};

/// RF output power in TX mode
pub const TxPwr = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    /// -18dBm
    dBm18 = 0x00,

    /// -12dBm
    dBm12 = 0x02,

    ///  -6dBm
    dBm6 = 0x04,

    ///   0dBm
    dBm0 = 0x06,
};

/// CRC encoding scheme
pub const Crc = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    /// CRC disabled
    off = 0x00,

    /// 1-byte CRC
    byte1 = 0x08,

    /// 2-byte CRC
    byte2 = 0x0c,
};

/// Power control
pub const Pwr = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    /// Power up
    /// Stanby-I mode with consumption about 26uA
    up = 0x02,

    /// Power down
    /// Stanby-II mode with consumption about 900nA
    down = 0x00,
};

pub const Mode = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    /// Receiver mode
    rx = 0x01,

    /// Transmitter mode
    tx = 0x00,
};

/// DynamicPayloadLength
pub const Dpl = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    on = 0x01,
    off = 0x00,
};

/// RX pipe addresses and TX address
pub const Pipe = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    pipe0 = 0x00,
    pipe1 = 0x01,
    pipe2 = 0x02,
    pipe3 = 0x03,
    pipe4 = 0x04,
    pipe5 = 0x05,

    /// TX address (not a pipe in fact)
    tx = 0x06,
};

/// State of auto acknowledgment for specified pipe
pub const Aa = enum(u8) {
    pub fn fromInt(val: u8) @This() {
        return @enumFromInt(val);
    }

    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }

    off = 0x00,
    on = 0x01,
};

/// Status of the RX FIFO
pub const StatusRxFifo = struct {
    /// The RX FIFO contains data and available locations
    pub const data: u8 = 0x00;

    /// The RX FIFO is empty
    pub const empty: u8 = 0x01;

    /// The RX FIFO is full
    pub const full: u8 = 0x02;

    /// Impossible state: RX FIFO cannot be empty and full at the same time
    pub const err: u8 = 0x03;
};

/// Status of the TX FIFO
pub const StatusTxFifo = struct {
    /// The TX FIFO contains data and available locations
    pub const data: u8 = 0x00;

    /// The TX FIFO is empty
    pub const empty: u8 = 0x01;

    /// The TX FIFO is full
    pub const full: u8 = 0x02;

    /// Impossible state: TX FIFO cannot be empty and full at the same time
    pub const err: u8 = 0x03;
};

/// Result of RX FIFO reading
pub const RxResult = enum(u8) {
    pub fn fromInt(val: u8) RxResult {
        return @enumFromInt(val);
    }

    pub fn toInt(self: RxResult) u8 {
        return @intFromEnum(self);
    }

    /// Packet received from the PIPE#0
    pipe0 = 0x00,

    /// Packet received from the PIPE#1
    pipe1 = 0x01,

    /// Packet received from the PIPE#2
    pipe2 = 0x02,

    /// Packet received from the PIPE#3
    pipe3 = 0x03,

    /// Packet received from the PIPE#4
    pipe4 = 0x04,

    /// Packet received from the PIPE#5
    pipe5 = 0x05,

    /// The RX FIFO is empty
    empty = 0xff,
};

/// Result of TX FIFO writing
pub const TxResult = struct {
    pub const err: u8 = 0x00;
    pub const success: u8 = 0x01;
    pub const timeout: u8 = 0x02;
    pub const max_rt: u8 = 0x03;
};

/// Addresses of the RX_PW_P# registers
pub const RxPwPipe: [6]Reg = [6]Reg{
    Reg.rx_pw_p0,
    Reg.rx_pw_p1,
    Reg.rx_pw_p2,
    Reg.rx_pw_p3,
    Reg.rx_pw_p4,
    Reg.rx_pw_p5,
};

/// Addresses of the address registers
pub const AddrRegs: [7]Reg = [7]Reg{
    Reg.rx_addr_p0,
    Reg.rx_addr_p1,
    Reg.rx_addr_p2,
    Reg.rx_addr_p3,
    Reg.rx_addr_p4,
    Reg.rx_addr_p5,
    Reg.tx_addr,
};
