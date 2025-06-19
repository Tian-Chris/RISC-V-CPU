//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/13/2025 10:32:39 AM
// Design Name: 
// Module Name: definitions
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//============
// privilege
//============
`define PRIV_USER        2'b00
`define PRIV_SUPER       2'b01
`define PRIV_MACHINE     2'b11

//==================
// CSR Instructions
//==================
`define CSRRW_INST       32'b001_00000_11100_11
`define CSRRS_INST       32'b010_00000_11100_11
`define CSRRC_INST       32'b011_00000_11100_11
`define CSRRWI_INST      32'b101_00000_11100_11
`define CSRRSI_INST      32'b110_00000_11100_11
`define CSRRCI_INST      32'b111_00000_11100_11
`define CSRRCI_INST      32'b111_00000_11100_11
`define CSR_INST_MASK    32'b111_00000_11111_11

`define MRET_INST        32'h30200073
`define ECALL_INST       32'h00000073

`define CSR_OPP_DN       4'b0000 //do nothing
`define CSR_OPP_RW       4'b0001
`define CSR_OPP_RS       4'b0010
`define CSR_OPP_RC       4'b0011
`define CSR_OPP_RWI      4'b0100
`define CSR_OPP_RSI      4'b0101
`define CSR_OPP_RCI      4'b0110

//===============
// CSR Addresses
//===============
`define mstatus_ADDR     12'h300
`define mstatus_MASK     32'b1000_0000_0111_1111_1111_1111_1110_1010
`define mstatush_ADDR    12'h310
`define mstatush_MASK    32'b0000_0000_0000_0000_0000_0000_0001_1000
`define misa_ADDR        12'h301
`define misa_MASK        32'hFFFFFFFF
`define medeleg_ADDR     12'h302
`define medeleg_MASK     32'hFFFFFFFF
`define mideleg_ADDR     12'h303
`define mideleg_MASK     32'hFFFFFFFF
`define mie_ADDR         12'h304
`define mie_MASK         32'hFFFFFFFF //note
`define mtvec_ADDR       12'h305
`define mtvec_MASK       32'hFFFFFFFF
`define mscratch_ADDR    12'h340
`define mscratch_MASK    32'hFFFFFFFF
`define mepc_ADDR        12'h341
`define mepc_MASK        32'hFFFFFFFF
`define mcause_ADDR      12'h342
`define mcause_MASK      32'h8000000F
`define mtval_ADDR       12'h343
`define mtval_MASK       32'hFFFFFFFF
`define mip_ADDR         12'h344
`define mip_MASK         32'hFFFFFFFF //note irq
`define mcycle_ADDR      12'hB00
`define mcycle_MASK      32'hFFFFFFFF
`define mcycleh_ADDR     12'hB80
`define mcycleh_MASK     32'hFFFFFFFF
`define mhartid_ADDR     12'hF14
`define mhartid_MASK     32'hFFFFFFFF

// =============
//  CSR Bits
// =============
`define MSTATUS_SIE        1
`define MSTATUS_MIE        3
`define MSTATUS_SPIE       5
`define MSTATUS_UBE        6
`define MSTATUS_MPIE       7
`define MSTATUS_SPP        8
`define MSTATUS_VS         10:9
`define MSTATUS_MPP        12:11
`define MSTATUS_FS         14:13
`define MSTATUS_XS         16:15
`define MSTATUS_MPRV       17
`define MSTATUS_SUM        18
`define MSTATUS_MXR        19
`define MSTATUS_TVM        20
`define MSTATUS_TW         21
`define MSTATUS_TSR        22
`define MSTATUS_SD         31

`define MSTATUSH_SBE       4
`define MSTATUSH_MBE       5

// =============
//  Exceptions
// =============
`define EXCEPT_MISALIGNED_PC     6'h10
`define EXCEPT_ECALL_U           6'h18
`define EXCEPT_ECALL_S           6'h19
`define EXCEPT_ECALL_M           6'h1B
