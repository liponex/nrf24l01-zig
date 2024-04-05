//! Command definitions\
//! From the [nRF24L01+ datasheet](https://docs.nordicsemi.com/bundle/nRF24L01P_PS_v1.0/resource/nRF24L01P_PS_v1.0.pdf)

/// Read command and status registers.\
/// LSByte first.
pub const r_register: u8 = 0b0000_0000;

/// Write command and status registers.\
/// Can be executed in power down or standby modes only.\
/// LSByte first.
pub const w_register: u8 = 0b0010_0000;

/// Read RX-payload: 1 – 32 bytes.\
/// A read operation always starts at byte 0.\
/// Payload is deleted from FIFO after it is read.\
/// Used in RX mode.\
/// LSByte first.
pub const r_rx_payload: u8 = 0b0110_0001;

/// Write TX-payload: 1 – 32 bytes.\
/// A write operation always starts at byte 0 used in TX payload.\
/// LSByte first.
pub const w_tx_payload: u8 = 0b1010_0000;

/// Flush TX FIFO, used in TX mode.
pub const flush_tx: u8 = 0b1110_0001;

/// Flush RX FIFO, used in RX mode.\
/// Should not be executed during transmission of acknowledge,
/// that is, acknowledge package will not be completed.
pub const flush_rx: u8 = 0b1110_0010;

/// Used for a PTX device.\
/// Reuse last transmitted payload.\
/// TX payload reuse is active until W_TX_PAYLOAD or FLUSH TX is executed.\
/// TX payload reuse must not be activated or deactivated during package transmission.
pub const reuse_tx_pl: u8 = 0b1110_0011;

/// Read RX payload width for the top R_RX_PAYLOAD in the RX FIFO.
pub const r_rx_pl_wid: u8 = 0b0110_0000;

/// Used in RX mode.\
/// Write Payload to be transmitted together with ACK packet on PIPE X.
/// (0 <= X <= 5).\
/// Maximum three ACK packet payloads can be pending.\
/// Payloads with same X are handled using first in - first out principle.\
/// Write payload: 1– 32 bytes. A write operation always starts at byte 0.\
/// LSByte first.
pub const w_ack_payload: u8 = 0b1010_1000;

/// Used in TX mode. Disables AUTOACK on this specific packet.
pub const w_tx_payload_noack: u8 = 0b1011_0000;

/// No operation (used for reading status register)
pub const nop: u8 = 0b1111_1111;

// /// (De)Activates R_RX_PL_WID, W_ACK_PAYLOAD, W_TX_PAYLOAD_NOACK features
// pub const activate: u8 = 0x0101_0000;
//
// /// Lock/unlock exclusive features
// pub const lock_unlock: u8 = 0x50;
