`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/21/2025 11:24:30 AM
// Design Name: 
// Module Name: branch_comp
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


module branch_comp(
    input wire sign_select,
    input wire [31:0] rdata1,
    input wire [31:0] rdata2,
    input wire [1:0] forwardBranchA,
    input wire [1:0] forwardBranchB,
    input wire [31:0] MEMAlu,
    input wire [31:0] WBdmem,
    input wire [31:0] WBAlu,
    input wire [31:0] WBPC,
    input wire [1:0] WBSel,
    output wire equal,
    output wire less_than
    );
    wire signed [31:0] r1_s;
    wire signed [31:0] r2_s;
    wire [31:0] wdata;
    wire [31:0] a, b;

    
    assign wdata = (WBSel == 2'b00) ? WBdmem : 
                   (WBSel == 2'b01) ? WBAlu : WBPC + 4;

    assign a = forwardBranchA[1] ? MEMAlu : (forwardBranchA[0] ? wdata : rdata1);
    assign b = forwardBranchB[1] ? MEMAlu : (forwardBranchB[0] ? wdata : rdata2);
    
    assign r1_s = $signed(a);
    assign r2_s = $signed(b);
    
    assign less_than = (!sign_select) ? (r1_s < r2_s) : (a < b);
    assign equal     = (a == b);
endmodule
