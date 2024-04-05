const std = @import("std");
const Allocator = std.mem.Allocator;

const testing = std.testing;
const testenv = @import("testenv");
const log = std.log.scoped(.nrf24l01);

const definitions = @import("definitions.zig");

pub const Cmd = definitions.Cmd;
pub const Reg = definitions.Reg;
pub const Config = definitions.Config;
pub const Feature = definitions.Feature;
pub const Flag = definitions.Flag;
pub const Mask = definitions.Mask;
pub const Ard = definitions.Ard;
pub const Dr = definitions.Dr;
pub const TxPwr = definitions.TxPwr;
pub const Crc = definitions.Crc;
pub const Pwr = definitions.Pwr;
pub const Mode = definitions.Mode;
pub const Dpl = definitions.Dpl;
pub const Pipe = definitions.Pipe;
pub const Aa = definitions.Aa;
pub const StatusRxFifo = definitions.StatusRxFifo;
pub const StatusTxFifo = definitions.StatusTxFifo;
pub const RxResult = definitions.RxResult;
pub const TxResult = definitions.TxResult;
pub const RxPwPipe = definitions.RxPwPipe;
pub const AddrRegs = definitions.AddrRegs;

const testAddr = definitions.testAddr;

/// **Implement** the deactivation of the CE pin
pub var ceL: *const fn () void = undefined;

/// **Implement** the activation of the CE pin
pub var ceH: *const fn () void = undefined;

/// **Implement** the deactivation of the CSN pin
pub var csnL: *const fn () void = undefined;

/// **Implement** the activation of the CSN pin
pub var csnH: *const fn () void = undefined;

/// **Implement** reading and writing to the SPI bus
pub var llRw: *const fn (u8) u8 = undefined;

pub const Status = struct {
    rx_data_ready: bool = false,
    tx_data_sent: bool = false,
    max_retransmissions: bool = false,
    rx_pipe: RxResult = RxResult.empty,
    tx_full: bool = false,
};

/// Set transceiver to it's initial state
///
/// note: RX/TX pipe addresses remains untouched
pub fn init() void {
    // Write to registers their initial values
    writeReg(Reg.config.toInt(), 0b0000_1000);

    // Enable 'Auto Acknowledgment' for all pipes
    writeReg(Reg.en_aa.toInt(), 0b0011_1111);
    writeReg(Reg.en_rx_addr.toInt(), 0x03);
    writeReg(Reg.setup_aw.toInt(), 0x03);
    writeReg(Reg.setup_retr.toInt(), 0x03);
    writeReg(Reg.rf_ch.toInt(), 0x02);
    writeReg(Reg.rf_setup.toInt(), 0x0E);
    writeReg(Reg.status.toInt(), 0x00);
    writeReg(Reg.rx_pw_p0.toInt(), 0x00);
    writeReg(Reg.rx_pw_p1.toInt(), 0x00);
    writeReg(Reg.rx_pw_p2.toInt(), 0x00);
    writeReg(Reg.rx_pw_p3.toInt(), 0x00);
    writeReg(Reg.rx_pw_p4.toInt(), 0x00);
    writeReg(Reg.rx_pw_p5.toInt(), 0x00);
    writeReg(Reg.dynpd.toInt(), 0x00);
    writeReg(Reg.feature.toInt(), 0x00);

    // Clear the FIFO's
    flushRx();
    flushTx();

    // Clear any pending interrupt flags
    clearIrqFlags();

    // Deassert CSN pin (chip release)
    csnH();
}

test "init" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    init();
}

/// Read a register
///
/// input:
/// * reg - register to read
///
/// return: value of register
pub fn readReg(reg: u8) u8 {
    var value: u8 = undefined;

    csnL();
    _ = llRw(reg & Mask.reg_map);
    value = llRw(Cmd.nop);
    csnH();

    return value;
}

test "Test readReg" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    const result = readReg(Reg.config.toInt());
    try testing.expectEqual(
        testenv.getLastByte(),
        result,
    );
}

/// Write a new value to register
///
/// input:
/// * reg - register to write
/// * value - value to write
pub fn writeReg(reg: u8, value: u8) void {
    csnL();
    if (reg < Cmd.w_register) {
        // This is a register access
        _ = llRw(Cmd.w_register | (reg & Mask.reg_map));
        _ = llRw(value);
    } else {
        // This is a single byte command or future command/register
        _ = llRw(reg);
        if ((reg != Cmd.flush_tx) and (reg != Cmd.flush_rx) and
            (reg != Cmd.reuse_tx_pl) and (reg != Cmd.nop))
        {
            // Send register value
            _ = llRw(value);
        }
    }
    csnH();
}

test "writeReg" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    writeReg(Reg.config.toInt(), 0x08);
}

/// Read a multi-byte register
///
/// input:
/// * reg - register to read
/// * buf - buffer for register data
pub fn readMbReg(reg: u8, buf: []u8) !void {
    if (buf.len > 32) {
        return error.PayloadTooLong;
    }

    csnL();
    _ = llRw(reg);
    for (0..buf.len) |i| {
        buf[i] = llRw(Cmd.nop);
    }
    csnH();
}

test "readMbReg normal buffer len" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    var allocator = testing.allocator;

    const buf_len = 32;
    const buf = try allocator.alloc(u8, buf_len);
    defer allocator.free(buf);

    try readMbReg(Cmd.r_rx_payload, buf);

    const mock_bytes = try testenv.getMockWithOffset(allocator, 32, 1);
    defer allocator.free(mock_bytes);

    try testing.expectEqualSlices(
        u8,
        mock_bytes,
        buf,
    );
}

test "readMbReg too big buffer len" {
    var allocator = testing.allocator;

    const long_buf = try allocator.alloc(u8, 33);
    defer allocator.free(long_buf);

    try testing.expectError(
        error.PayloadTooLong,
        readMbReg(Cmd.r_rx_payload, long_buf),
    );
}

/// Write a multi-byte register
///
/// input:
/// * reg - register to write
/// * buf - buffer with data to write
pub fn writeMbReg(reg: u8, buf: []u8) !void {
    if (buf.len > 32) {
        return error.PayloadTooLong;
    }

    csnL();
    _ = llRw(reg);
    for (0..buf.len) |i| {
        _ = llRw(buf[i]);
    }
    csnH();
}

test "writeMbReg normal buffer len" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    var allocator = testing.allocator;

    const buf = try allocator.alloc(u8, 32);
    defer allocator.free(buf);

    try writeMbReg(Cmd.w_tx_payload, buf);
}

test "writeMbReg too big buffer len" {
    var allocator = testing.allocator;

    const long_buf = try allocator.alloc(u8, 33);
    defer allocator.free(long_buf);

    try testing.expectError(
        error.PayloadTooLong,
        writeMbReg(Cmd.w_tx_payload, long_buf),
    );
}

/// Check if the nRF24L01 present
///
/// return:
/// * true - nRF24L01 is online and responding
/// * false - received sequence differs from original
pub fn check(allocator: Allocator) !bool {
    const rxbuf: []u8 = try allocator.alloc(u8, 5);
    defer allocator.free(rxbuf);
    const ptr: []u8 = @constCast(testAddr);

    try setAddrWidth(testAddr.len);

    // Write test TX address and read TX_ADDR register
    try writeMbReg(Cmd.w_register | Reg.tx_addr.toInt(), ptr);
    try readMbReg(Cmd.r_register | Reg.tx_addr.toInt(), rxbuf);

    if (std.mem.eql(u8, rxbuf, ptr)) {
        return true;
    }

    return false;
}

test "check" {
    const allocator = testing.allocator;
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);

    try testing.expect(!try check(allocator));
}

/// Control transceiver power mode
///
/// input:
/// * mode - new state of power mode
pub fn setPowerMode(mode: Pwr) void {
    var reg: u8 = undefined;

    reg = readReg(Reg.config.toInt());
    if (mode == .up) {
        reg |= Config.pwr_up;
    } else {
        reg &= ~Config.pwr_up;
    }
    writeReg(Reg.config.toInt(), reg);
}

test "setPowerMode" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    setPowerMode(.up);
}

/// Set transceiver operational mode
///
/// input:
/// * mode - operational mode
pub fn setOperationalMode(mode: Mode) void {
    var reg: u8 = undefined;

    // Configure PRIM_RX bit of the CONFIG register
    reg = readReg(Reg.config.toInt());
    reg &= ~Config.prim_rx;
    reg |= (mode.toInt() & Config.prim_rx);
    writeReg(Reg.config.toInt(), reg);
}

test "setOperationalMode" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    setOperationalMode(.rx);
}

/// Set transceiver DynamicPayloadLength feature for all the pipes
/// input:
///   mode - status
pub fn setDynamicPayloadLength(mode: Dpl) void {
    var reg: u8 = undefined;
    reg = readReg(Reg.feature.toInt());
    if (mode == Dpl.on) {
        writeReg(Reg.feature.toInt(), reg | Feature.en_dpl);
        writeReg(Reg.dynpd.toInt(), 0b0011_1111);
    } else {
        writeReg(Reg.feature.toInt(), reg & ~Feature.en_dpl);
        writeReg(Reg.dynpd.toInt(), 0x0);
    }
}

test "setDynamicPayloadLength" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    setDynamicPayloadLength(.on);
}

/// Turn Payload with ACK feature
/// input:
///   mode - status, 1 or 0
pub fn setPayloadWithAck(mode: u8) !void {
    if (mode > 1) {
        return error.WrongMode;
    }

    var reg: u8 = undefined;
    reg = readReg(Reg.feature.toInt());
    if (mode == 1) {
        writeReg(Reg.feature.toInt(), reg | Feature.en_ack_pay);
    } else {
        writeReg(Reg.feature.toInt(), reg & ~Feature.en_ack_pay);
    }
}

test "setPayloadWithAck" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try setPayloadWithAck(1);
    try testing.expectError(
        error.WrongMode,
        setPayloadWithAck(2),
    );
}

/// Configure transceiver CRC scheme
/// input:
///   scheme - CRC scheme
/// note: transceiver will forcibly turn on the CRC in case if auto acknowledgment
///       enabled for at least one RX pipe
pub fn setCrcScheme(scheme: Crc) void {
    var reg: u8 = undefined;

    // Configure EN_CRC[3] and CRCO[2] bits of the CONFIG register
    reg = readReg(Reg.config.toInt());
    reg &= ~Mask.crc;
    reg |= (scheme.toInt() & Mask.crc);
    writeReg(Reg.config.toInt(), reg);
}

test "setCrcScheme" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    setCrcScheme(.byte2);
}

/// Set frequency channel
/// input:
///   channel - radio frequency channel, value from 0 to 127
/// note: frequency will be (2400 + channel)MHz
/// note: PLOS_CNT[7:4] bits of the OBSERVER_TX register will be reset
pub fn setRfChannel(channel: u8) !void {
    if (channel > 127) {
        return error.WrongChannelNumber;
    }

    writeReg(Reg.rf_ch.toInt(), channel);
}

test "setRfChannel normal" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try setRfChannel(0);
}

test "setRfChannel too big channel" {
    try testing.expectError(
        error.WrongChannelNumber,
        setRfChannel(128),
    );
}

/// Set automatic retransmission parameters
/// input:
///   ard - auto retransmit delay
///   arc - count of auto retransmits, value form 0 to 15
/// note: zero arc value means that the automatic retransmission disabled
pub fn setAutoRetr(ard: Ard, arc: u8) !void {
    if (arc > 15) {
        return error.ArcTooBig;
    }

    writeReg(
        Reg.setup_retr.toInt(),
        ((@as(u8, ard.toInt()) << 4) | (arc & Mask.retr_arc)),
    );
}

test "setAutoRetr normal" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try setAutoRetr(Ard.us750, 15);
}

test "setAutoRetr too big Arc" {
    try testing.expectError(
        error.ArcTooBig,
        setAutoRetr(Ard.us750, 16),
    );
}

/// Set of address widths
/// input:
///   addr_width - RX/TX address field width, value from 3 to 5
/// note: this setting is common for all pipes
pub fn setAddrWidth(addr_width: u8) !void {
    if (addr_width < 3 or addr_width > 5) {
        return error.WrongAddrWidth;
    }

    writeReg(Reg.setup_aw.toInt(), addr_width - 2);
}

test "setAddrWidth normal" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try setAddrWidth(3);
}

test "setAddrWidth too small" {
    try testing.expectError(
        error.WrongAddrWidth,
        setAddrWidth(2),
    );
}

test "setAddrWidth too big" {
    try testing.expectError(
        error.WrongAddrWidth,
        setAddrWidth(6),
    );
}

/// Set static RX address for a specified pipe
/// input:
///   pipe - pipe to configure address
///   addr - buffer with address
/// note: pipe can be a number from 0 to 5 (RX pipes) and 6 (TX pipe)
/// note: buffer length must be equal to current address width of transceiver
/// note: for pipes[2..5] only first byte of address will be written because
///       other bytes of address equals to pipe1
/// note: for pipes[2..5] only first byte of address will be written because
///       pipes 1-5 share the four most significant address bytes
pub fn setAddr(pipe: Pipe, addr: []u8) !void {
    if (3 > addr.len or addr.len > 5) {
        return error.WrongAddrWidth;
    }

    var addr_width: u8 = undefined;

    switch (pipe) {
        .tx, .pipe0, .pipe1 => {
            addr_width = readReg(Reg.setup_aw.toInt()) + 1;

            if ((addr.len - 1) != addr_width) {
                std.debug.print(
                    "\naddr_width: {d}\naddr.len: {d}\n",
                    .{ addr_width, addr.len },
                );
                return error.WrongAddrWidth;
            }

            csnL();
            _ = llRw(Cmd.w_register | AddrRegs[pipe.toInt()].toInt());
            // Write address in reverse order (LSByte first)
            var i = addr_width;
            while (i > 0) {
                i -= 1;
                _ = llRw(addr[i]);
            }
            csnH();
        },
        .pipe2, .pipe3, .pipe4, .pipe5 => {
            writeReg(AddrRegs[pipe.toInt()].toInt(), addr[0]);
        },
    }
}

test "setAddr normal" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    testenv.skip(2);

    var allocator = testing.allocator;

    const addr = try allocator.alloc(u8, 5);
    defer allocator.free(addr);

    try setAddr(.pipe1, addr);
}

test "setAddr too small" {
    var allocator = testing.allocator;

    const addr = try allocator.alloc(u8, 2);
    defer allocator.free(addr);

    try testing.expectError(
        error.WrongAddrWidth,
        setAddr(.pipe1, addr),
    );
}

test "setAddr too big" {
    var allocator = testing.allocator;

    const addr = try allocator.alloc(u8, 6);
    defer allocator.free(addr);

    try testing.expectError(
        error.WrongAddrWidth,
        setAddr(.pipe1, addr),
    );
}

/// Configure RF output power in TX mode
/// input:
///   tx_pwr - RF output power
pub fn setTxPower(tx_pwr: TxPwr) void {
    var reg: u8 = undefined;

    reg = readReg(Reg.rf_setup.toInt());
    reg &= ~Mask.rf_pwr;
    reg |= tx_pwr.toInt();
    writeReg(Reg.rf_setup.toInt(), reg);
}

test "setTxPower" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    setTxPower(.dBm0);
}

/// Configure transceiver data rate
/// input:
///   data_rate - data rate
pub fn setDataRate(data_rate: Dr) void {
    var reg: u8 = undefined;

    reg = readReg(Reg.rf_setup.toInt());
    reg &= ~Mask.datarate;
    reg |= data_rate.toInt();
    writeReg(Reg.rf_setup.toInt(), reg);
}

test "setDataRate" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    setDataRate(.kbps250);
}

/// Configure a specified RX pipe
/// input:
///   pipe - RX pipe
///   aa_state - state of auto acknowledgment
///   payload_len - payload length in bytes
pub fn setRxPipe(pipe: Pipe, aa_state: Aa, payload_len: u8) !void {
    if (pipe == .tx) {
        return error.WrongPipeNumper;
    }
    const pipe_bit: u8 = (@as(u8, 1) << @truncate(pipe.toInt()));
    var reg: u8 = undefined;

    // Enable the specified pipe (EN_RXADDR register)
    reg = (readReg(Reg.en_rx_addr.toInt()) | pipe_bit) & Mask.en_rx;
    writeReg(Reg.en_rx_addr.toInt(), reg);

    // Set RX payload length (RX_PW_Px register)
    writeReg(RxPwPipe[pipe.toInt()].toInt(), payload_len & Mask.rx_pw);

    // Set auto acknowledgment for a specified pipe (EN_AA register)
    reg = readReg(Reg.en_aa.toInt());
    if (aa_state == Aa.on) {
        reg |= pipe_bit;
    } else {
        reg &= ~pipe_bit;
    }
    writeReg(Reg.en_aa.toInt(), reg);
}

test "setRxPipe" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try setRxPipe(.pipe1, .on, 32);
}

test "setRxPipe tx pipe" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try testing.expectError(
        error.WrongPipeNumper,
        setRxPipe(.tx, .on, 32),
    );
}

/// Disable specified RX pipe
/// input:
///   pipe - RX pipe
pub fn closePipe(pipe: Pipe) !void {
    if (pipe == .tx) {
        return error.WrongPipeNumper;
    }

    var reg: u8 = undefined;

    reg = readReg(Reg.en_rx_addr.toInt());
    reg &= ~(@as(u8, 1) << @truncate(pipe.toInt()));
    reg &= Mask.en_rx;
    writeReg(Reg.en_rx_addr.toInt(), reg);
}

test "closePipe" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try closePipe(.pipe1);
}

test "closePipe tx pipe" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try testing.expectError(
        error.WrongPipeNumper,
        closePipe(.tx),
    );
}

/// Enable the 'Auto Acknowledgment' (a.k.a. enhanced ShockBurst) for RX pipe
/// input:
///   pipe - RX pipe
pub fn enableAa(pipe: Pipe) !void {
    if (pipe == .tx) {
        return error.WrongPipeNumper;
    }

    var reg: u8 = undefined;

    // Set bit in EN_AA register
    reg = readReg(Reg.en_aa.toInt());
    reg |= (@as(u8, 1) << @truncate(pipe.toInt()));
    writeReg(Reg.en_aa.toInt(), reg);
}

test "enableAa" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try enableAa(.pipe1);
}

test "enableAa tx pipe" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try testing.expectError(
        error.WrongPipeNumper,
        enableAa(.tx),
    );
}

/// Enable the 'Auto Acknowledgment' (a.k.a. enhanced ShockBurst) for all RX pipes
pub fn enableAaForAll() void {
    // Enable all bits in the EN_AA register
    writeReg(Reg.en_aa.toInt(), 0b0011_1111);
}

test "enableAaForAll" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    enableAaForAll();
}

/// Disable the 'Auto Acknowledgment' (a.k.a. enhanced ShockBurst) for RX pipe
/// input:
///   pipe - RX pipe
pub fn disableAa(pipe: Pipe) !void {
    if (pipe == .tx) {
        return error.WrongPipeNumper;
    }

    // Clear bit in the EN_AA register
    var reg: u8 = readReg(Reg.en_aa.toInt());
    reg &= ~(@as(u8, 1) << @truncate(pipe.toInt()));
    writeReg(Reg.en_aa.toInt(), reg);
}

test "disableAa pipe0" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try disableAa(.pipe0);
    try disableAa(.pipe1);
    try disableAa(.pipe2);
    try disableAa(.pipe3);
    try disableAa(.pipe4);
    try disableAa(.pipe5);
}

test "disableAa tx pipe" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try testing.expectError(
        error.WrongPipeNumper,
        disableAa(.tx),
    );
}

/// Disable the 'Auto Acknowledgment' (a.k.a. enhanced ShockBurst) for all RX pipes
pub fn disableAaForAll() void {
    // Clear all bits in the EN_AA register
    writeReg(Reg.en_aa.toInt(), 0);
}

test "disableAa for all" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    disableAaForAll();
}

/// Get pending IRQ flags
/// return: current status of RX_DR, TX_DS and MAX_RT bits of the STATUS register
pub fn getIrqFlags() u8 {
    return (readReg(Reg.status.toInt()) & Mask.status_irq);
}

test "getIrqFlags" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    const result = getIrqFlags();
    try testing.expectEqual(
        ((testenv.getLastByte()) & Mask.status_irq),
        result,
    );
}

/// Get value of the STATUS register
/// return: value of STATUS register
pub fn getStatus() u8 {
    return readReg(Reg.status.toInt());
}

test "getStatus" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    const result = getStatus();
    try testing.expectEqual(
        testenv.getLastByte(),
        result,
    );
}

/// Get status of the RX FIFO
/// return: one of the nRF24_STATUS_RXFIFO_xx values
pub fn getStatusRxFifo() u8 {
    return (readReg(Reg.fifo_status.toInt()) & Mask.rx_fifo);
}

test "getStatusRxFifo" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    const result = getStatusRxFifo();
    try testing.expectEqual(
        (testenv.getLastByte() & Mask.rx_fifo),
        result,
    );
}

/// Get status of the TX FIFO
/// return: one of the nRF24_STATUS_TXFIFO_xx values
/// note: the TX_REUSE bit ignored
pub fn getStatusTxFifo() u8 {
    return ((readReg(Reg.fifo_status.toInt()) & Mask.tx_fifo) >> 4);
}

test "getStatusTxFifo" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    const result = getStatusTxFifo();
    try testing.expectEqual(
        (testenv.getLastByte() & Mask.tx_fifo) >> 4,
        result,
    );
}

/// Get pipe number for the payload available for reading from RX FIFO
/// return: pipe number or 0x07 if the RX FIFO is empty
pub fn getRxSource() u8 {
    return ((readReg(Reg.status.toInt()) & Mask.rx_p_no) >> 1);
}

test "getRxSource" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    const result = getRxSource();
    try testing.expectEqual(
        ((testenv.getLastByte() & Mask.rx_p_no) >> 1),
        result,
    );
}

/// Get auto retransmit statistic
///
/// return: value of OBSERVE_TX register which contains two counters encoded in nibbles:
/// * high - lost packets count
/// (max value 15, can be reseted by write to RF_CH register)
/// * low  - retransmitted packets count
/// (max value 15, reseted when new transmission starts)
pub fn getRetransmitCounters() u8 {
    return readReg(Reg.observe_tx.toInt());
}

test "getRetransmitCounters" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    try testing.expect(getRetransmitCounters() < 15);
}

/// Reset packet lost counter
pub fn resetPlos() void {
    var reg: u8 = undefined;

    // The PLOS counter is reset after write to RF_CH register
    reg = readReg(Reg.rf_ch.toInt());
    writeReg(Reg.rf_ch.toInt(), reg);
}

test "resetPlos" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    resetPlos();
}

/// Flush the TX FIFO
pub fn flushTx() void {
    writeReg(Cmd.flush_tx, Cmd.nop);
}

test "flushTx" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    flushTx();
}

/// Flush the RX FIFO
pub fn flushRx() void {
    writeReg(Cmd.flush_rx, Cmd.nop);
}

test "flushRx" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    flushRx();
}

/// Clear any pending IRQ flags
pub fn clearIrqFlags() void {
    var reg: u8 = undefined;

    // Clear RX_DR, TX_DS and MAX_RT bits of the STATUS register
    reg = readReg(Reg.status.toInt());
    reg |= Mask.status_irq;
    writeReg(Reg.status.toInt(), reg);
}

test "clearIrqFlags" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    clearIrqFlags();
}

/// Write TX payload
/// input:
///   buf - buffer with payload data
///   length - payload length in bytes
pub fn writePayload(buf: []u8) !void {
    try writeMbReg(Cmd.w_tx_payload, buf);
}

test "writePayload" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    var allocator = testing.allocator;

    const buf = try allocator.alloc(u8, 32);
    defer allocator.free(buf);

    try writePayload(buf);
}

/// Get RX payload width using DPL feature
/// return: payload width in bytes
pub fn getRxDplPayloadWidth() !u8 {
    var value: u8 = undefined;

    csnL();
    _ = llRw(Cmd.r_rx_pl_wid);
    value = llRw(Cmd.nop);
    csnH();

    if (value > 32) {
        flushRx();
        return error.PayloadTooLong;
    }

    return value;
}

test "getRxDplPayloadWidth" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    const result = try getRxDplPayloadWidth();
    try testing.expectEqual(
        testenv.getLastByte(),
        result,
    );
}

pub fn readPayloadGeneric(buf: []u8, dpl: bool) !RxResult {
    var pipe: u8 = undefined;
    var len: u8 = undefined;

    // Extract a payload pipe number from the STATUS register
    pipe = (readReg(Reg.status.toInt()) & Mask.rx_p_no) >> 1;
    if (pipe > 5) {
        return error.WrongPipeNumper;
    }

    if (dpl) {
        len = try getRxDplPayloadWidth();
    } else {
        len = readReg(RxPwPipe[pipe].toInt());
    }

    if (len == 0) {
        return RxResult.empty;
    }

    try readMbReg(Cmd.r_rx_payload, buf);

    return RxResult.fromInt(pipe);
}

test "readPayloadGeneric no DPL" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    var allocator = testing.allocator;

    const buf = try allocator.alloc(u8, 32);
    defer allocator.free(buf);

    _ = try readPayloadGeneric(buf, false);
}

test "readPayloadGeneric with DPL" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    var allocator = testing.allocator;

    const buf = try allocator.alloc(u8, 32);
    defer allocator.free(buf);

    _ = try readPayloadGeneric(buf, true);
}

/// Read payload available in the RX FIFO
/// input:
///   buf - buffer to store a payload data
/// return: RxResult value
///   pipeX - packet has been received from the pipe number X
///   empty - the RX FIFO is empty
pub fn readPayload(buf: []u8) !RxResult {
    return readPayloadGeneric(buf, false);
}

test "readPayload" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    var allocator = testing.allocator;

    const buf = try allocator.alloc(u8, 32);
    defer allocator.free(buf);

    _ = try readPayload(buf);
}

/// Read payload available in the RX FIFO
/// input:
///   buf - buffer to store a payload data
/// return: RxResult value
///   pipeX - packet has been received from the pipe number X
///   empty - the RX FIFO is empty
pub fn readPayloadDpl(buf: []u8) !RxResult {
    return readPayloadGeneric(buf, true);
}

test "readPayloadDpl" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    var allocator = testing.allocator;

    const buf = try allocator.alloc(u8, 32);
    defer allocator.free(buf);

    _ = try readPayloadDpl(buf);
}

pub fn getFeatures() u8 {
    return readReg(Reg.feature.toInt());
}

test "getFeatures" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    const result = getFeatures();
    try testing.expectEqual(
        testenv.getLastByte(),
        result,
    );
}

pub fn activateFeatures() void {
    csnL();
    _ = llRw(Cmd.activate);
    _ = llRw(0x73);
    csnH();
}

test "activateFeatures" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    activateFeatures();
}

pub fn writeAckPayload(pipe: Pipe, payload: []u8) void {
    csnL();
    _ = llRw(Cmd.w_ack_payload | pipe.toInt());
    for (0..payload.len) |i| {
        _ = llRw(payload[i]);
    }
    csnH();
}

test "writeAckPayload" {
    testenv.init(&llRw, &ceH, &ceL, &csnH, &csnL);
    var allocator = testing.allocator;

    const payload = try allocator.alloc(u8, 32);
    defer allocator.free(payload);

    writeAckPayload(Pipe.pipe1, payload);
}
