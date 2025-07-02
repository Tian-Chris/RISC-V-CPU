
//==============
// Instructions
//==============
`define INST_NOP         32'h00000013

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
`define CSR_INST_MASK    32'b111_00000_11111_11

`define MRET_INST        32'h30200073
`define SRET_INST        32'h10200073
`define ECALL_INST       32'h00000073

`define CSR_OPP_DN       4'b0000 //do nothing
`define CSR_OPP_RW       4'b0001
`define CSR_OPP_RS       4'b0010
`define CSR_OPP_RC       4'b0011
`define CSR_OPP_RWI      4'b0100
`define CSR_OPP_RSI      4'b0101
`define CSR_OPP_RCI      4'b0110

`define INST_FENCE       32'hf
`define INST_FENCE_MASK  32'h707f
`define INST_SFENCE      32'h12000073
`define INST_SFENCE_MASK 32'hfe007fff
`define INST_IFENCE      32'h100f
`define INST_IFENCE_MASK 32'h707f

//===============
// CSR Addresses
//===============
//Machine:
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

//supervisor
//same reg
`define sstatus_ADDR     12'h100
`define sstatus_MASK     32'b1000_0000_0000_1101_1110_0001_0110_0010
`define sie_ADDR         12'h104
`define sie_MASK         32'hFFFFFFFF //
`define sip_ADDR         12'h144
`define sip_MASK         32'hFFFFFFFF //

//dif
`define stvec_ADDR       12'h105
`define stvec_MASK       32'hFFFFFFFF
`define sscratch_ADDR    12'h140
`define sscratch_MASK    32'hFFFFFFFF
`define sepc_ADDR        12'h141
`define sepc_MASK        32'hFFFFFFFF
`define scause_ADDR      12'h142
`define scause_MASK      32'h8000000F
`define stval_ADDR       12'h143
`define stval_MASK       32'hFFFFFFFF
`define satp_ADDR        12'h180
`define satp_MASK        32'hFFFFFFFF

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

`define MIP_MSIP           3
`define MIP_MTIP           7
`define MIP_MEIP           11

`define MIE_MSIE           3
`define MIE_MTIE           7
`define MIE_MEIE           11

// =============
//  Exceptions
// =============
`define EXCEPT_MISALIGNED_PC     5'h00
`define EXCEPT_ACCESS_FAULT      5'h01
`define EXCEPT_ILLEGAL_INST      5'h02
`define EXCEPT_BREAKPOINT        5'h03
`define EXCEPT_LOAD_MISALIGNED   5'h04
`define EXCEPT_LOAD_FAULT        5'h05
`define EXCEPT_STORE_MISALIGNED  5'h06
`define EXCEPT_STORE_FAULT       5'h07
`define EXCEPT_ECALL_U           5'h08
`define EXCEPT_ECALL_S           5'h09
`define EXCEPT_ECALL_M           5'h0B
`define EXCEPT_INST_PAGE_FAULT   5'h0C
`define EXCEPT_LOAD_PAGE_FAULT   5'h0D
`define EXCEPT_STORE_PAGE_FAULT  5'h0F
`define EXCEPT_DO_NOTHING        5'h1F

// =============
//  Interrupts
// =============
`define INTER_MSIP        5'h13
`define INTER_MTIP        5'h17
`define INTER_MEIP        5'h1B

// ===============
//   Peripherals
// ===============
`define UART_WRITE_ADDR          32'h10000000
`define UART_READ_ADDR           32'h10000005
`define CLINT_MSIP_ADDR          32'h02000000
`define CLINT_MTIMECMP_ADDR      32'h02004000
`define CLINT_MTIMECMPH_ADDR     32'h02004004
`define CLINT_MTIME_ADDR         32'h0200BFF8
`define CLINT_MTIMEH_ADDR        32'h0200BFFC
