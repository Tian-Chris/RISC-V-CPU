`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/12/2025 01:32:59 PM
// Design Name: 
// Module Name: csr_file
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

module csr_file (
    input  wire        clk,
    input  wire        rst,
     
    //csr write
    input  wire        csr_wen,
    input  wire [11:0] csr_waddr,
    input  wire [31:0] csr_wdata,
    
    //csr read
    input  wire        csr_ren,
    input  wire [11:0] csr_raddr,
    output wire [31:0] csr_rdata,
    output wire [31:0] csr_status

);
`include "csr_defs.v"
//all unused
reg [31:0] csrzero;

//future
reg  [31:0] mstatus_f;
reg  [31:0] mstatush_f;

//current
reg  [31:0] mstatus_c;
reg  [31:0] mstatush_c;

//read
reg  [31:0] rdata;
always @(*) begin
    rdata = 32'b0;
    if(csr_ren) begin
    case(csr_raddr)
        `mstatus_ADDR:   rdata = (mstatus_c & ~`mstatus_RMASK) | (csr_wdata & `mstatus_RMASK);
        `mstatush_ADDR:  rdata = (mstatush_c & ~`mstatush_RMASK) | (csr_wdata & `mstatush_RMASK);
        default:         rdata = 32'b0;
    endcase
    end
end
assign csr_rdata = rdata;
assign csr_status = mstatus_c;

//write back
always @(*) begin
    mstatus_f = mstatus_c;
    mstatush_f = mstatush_c;
    if(csr_wen) begin
    case(csr_waddr)
        `mstatus_ADDR:   mstatus_f  = (mstatus_f & ~`mstatus_WMASK) | (csr_wdata & `mstatus_WMASK);
        `mstatush_ADDR:  mstatush_f = (mstatush_f & ~`mstatush_WMASK) | (csr_wdata & `mstatush_WMASK);
        default:         csrzero    = 32'b0;
    endcase
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        csrzero    <= 32'b0;
        mstatus_c  <= 32'b0;
        mstatush_c <= 32'b0;
    end else
    begin
        mstatus_c  <= mstatus_f;
        mstatush_c <= mstatush_f;
    end
end
endmodule