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

`define CSRRW_INST       32'b001_00000_11100_11
`define CSRRS_INST       32'b010_00000_11100_11
`define CSRRC_INST       32'b011_00000_11100_11
`define CSRRWI_INST      32'b101_00000_11100_11
`define CSRRSI_INST      32'b110_00000_11100_11
`define CSRRCI_INST      32'b111_00000_11100_11
`define CSR_INST_MASK    32'b111_00000_11111_11

`define CSR_OPP_DN       4'b0000 //do nothing
`define CSR_OPP_RW       4'b0001
`define CSR_OPP_RS       4'b0010
`define CSR_OPP_RC       4'b0011
`define CSR_OPP_RWI      4'b0100
`define CSR_OPP_RSI      4'b0101
`define CSR_OPP_RCI      4'b0110

`define mstatus_ADDR     12'h300
`define mstatus_RMASK    32'b1000_0000_0111_1111_1111_1111_1110_1010
`define mstatus_WMASK    32'b1000_0000_0111_1111_1111_1111_1110_1010
`define mstatush_ADDR    12'h310
`define mstatush_RMASK   32'b0000_0000_0000_0000_0000_0000_0001_1000
`define mstatush_WMASK   32'b0000_0000_0000_0000_0000_0000_0001_1000
 
