`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/13/2025 01:01:38 PM
// Design Name: 
// Module Name: csr_handler
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

module csr_handler(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] csr_inst,
    input  wire [31:0] csr_rs1,
    
    //csr write (comes from WB)
    input  wire        csr_wben,
    input  wire [11:0] csr_wbaddr,   //address written
    input  wire [31:0] csr_wbdata,   //data written
    
    output wire [31:0] csr_rresult, //result of read
    output wire [31:0] csr_data_to_wb  //csr_data_to_wb -> WB -> csr_wdata 
    );
    
`include "csr_defs.v"
//csr read
wire [3:0]  csr_op_type;       // CSR op: DN. RW/I, RS/I, RC/I
wire [11:0] csr_raddr;
wire        csr_ren;
wire [31:0] csr_rdata;
wire [31:0] csr_status;
wire [31:0] zimm;

assign csr_op_type = ((csr_inst & `CSR_INST_MASK) == `CSRRW_INST) ? `CSR_OPP_RW :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRS_INST) ? `CSR_OPP_RS :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRC_INST) ? `CSR_OPP_RC :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRWI_INST) ? `CSR_OPP_RWI :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRSI_INST) ? `CSR_OPP_RSI :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRCI_INST) ? `CSR_OPP_RCI : `CSR_OPP_DN;
assign csr_ren     = csr_op_type != `CSR_OPP_DN;
assign csr_raddr   = csr_inst[31:20];
assign zimm        = csr_inst[19:15];

csr_file csr (
    .clk(clk),
    .rst(rst),
    
    //csr write
    .csr_wen(csr_wben),
    .csr_waddr(csr_wbaddr),
    .csr_wdata(csr_wbdata),
    
    //csr read
    .csr_ren(csr_ren),
    .csr_raddr(csr_raddr),
    .csr_rdata(csr_rdata),
    .csr_status(csr_status)
);

//read
reg [31:0] csr_rdata_clocked;
reg [31:0] output_data;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        csr_rdata_clocked <= 32'b0;
        output_data       <= 32'b0;
    end 
    else begin
        csr_rdata_clocked <= csr_rdata;
        case(csr_op_type)
            `CSR_OPP_RW:  output_data <= csr_rs1;
            `CSR_OPP_RS:  output_data <= csr_rs1 | csr_rdata;
            `CSR_OPP_RC:  output_data <= ~csr_rs1 & csr_rdata;
            `CSR_OPP_RWI: output_data <= zimm; 
            `CSR_OPP_RSI: output_data <= zimm | csr_rdata;
            `CSR_OPP_RCI: output_data <= ~zimm & csr_rdata;
            default:      output_data <= 32'b0;
        endcase
    end
end
assign csr_data_to_wb = output_data;
assign csr_rresult = csr_rdata_clocked;

endmodule