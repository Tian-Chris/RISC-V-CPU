
//==============
// Instructions
//==============
`define INST_NOP        32'h00000013

// R-Type
`define R_MASK          32'hfe00707f

`define INST_ADD        32'h33
`define INST_ADD_MASK   `R_MASK
`define INST_SUB        32'h40000033
`define INST_SUB_MASK   `R_MASK
`define INST_AND        32'h7033
`define INST_AND_MASK   `R_MASK
`define INST_OR         32'h6033
`define INST_OR_MASK    `R_MASK
`define INST_XOR        32'h4033
`define INST_XOR_MASK   `R_MASK
`define INST_SLL        32'h1033
`define INST_SLL_MASK   `R_MASK
`define INST_SRL        32'h5033
`define INST_SRL_MASK   `R_MASK
`define INST_SRA        32'h40005033
`define INST_SRA_MASK   `R_MASK
`define INST_SLT        32'h2033
`define INST_SLT_MASK   `R_MASK
`define INST_SLTU       32'h3033
`define INST_SLTU_MASK  `R_MASK

// I-Type
`define I_MASK          32'h707f

`define INST_ANDI       32'h7013
`define INST_ANDI_MASK  `I_MASK
`define INST_ADDI       32'h13
`define INST_ADDI_MASK  `I_MASK
`define INST_SLTI       32'h2013
`define INST_SLTI_MASK  `I_MASK
`define INST_SLTIU      32'h3013
`define INST_SLTIU_MASK `I_MASK
`define INST_ORI        32'h6013
`define INST_ORI_MASK   `I_MASK
`define INST_XORI       32'h4013
`define INST_XORI_MASK  `I_MASK

// I*_Type
`define ISTAR_MASK      32'hfe00707f

`define INST_SLLI       32'h1013
`define INST_SLLI_MASK  `ISTAR_MASK
`define INST_SRLI       32'h5013
`define INST_SRLI_MASK  `ISTAR_MASK
`define INST_SRAI       32'h40005013
`define INST_SRAI_MASK  `ISTAR_MASK

// S_Type
`define S_MASK          32'h707f

`define INST_LB         32'h3
`define INST_LB_MASK    `I_MASK
`define INST_LBU        32'h4003
`define INST_LBU_MASK   `I_MASK
`define INST_LH         32'h1003
`define INST_LH_MASK    `I_MASK
`define INST_LHU        32'h5003
`define INST_LHU_MASK   `I_MASK
`define INST_LW         32'h2003
`define INST_LW_MASK    `I_MASK
`define INST_SB         32'h23
`define INST_SB_MASK    `S_MASK
`define INST_SH          32'h1023
`define INST_SH_MASK    `S_MASK
`define INST_SW         32'h2023
`define INST_SW_MASK    `S_MASK

//B_Type        
`define B_MASK          32'h707f

`define INST_BEQ        32'h63
`define INST_BEQ_MASK   `B_MASK
`define INST_BNE        32'h1063
`define INST_BNE_MASK   `B_MASK
`define INST_BLT        32'h4063
`define INST_BLT_MASK   `B_MASK
`define INST_BGE        32'h5063
`define INST_BGE_MASK   `B_MASK
`define INST_BLTU       32'h6063
`define INST_BLTU_MASK  `B_MASK
`define INST_BGEU       32'h7063
`define INST_BGEU_MASK  `B_MASK

// J_type and U_Type
`define J_MASK          32'h7f
`define U_MASK          32'h7f

`define INST_JAL        32'h6f
`define INST_JAL_MASK   `J_MASK
`define INST_JALR       32'h67
`define INST_JALR_MASK  `I_MASK
`define INST_LUI        32'h37
`define INST_LUI_MASK   `U_MASK
`define INST_AUIPC      32'h17
`define INST_AUIPC_MASK `U_MASK

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

// ==================
//   Hazard Signals
// ==================

`define HS_DN               4'b0000
`define FLUSH_EARLY         4'b0001
`define FLUSH_ALL           4'b0010
`define STALL_EARLY         4'b0011
`define STALL_MMU           4'b0100
