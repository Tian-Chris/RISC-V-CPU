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
    output wire equal,
    output wire less_than
    );
    wire signed [31:0] r1_s;
    wire signed [31:0] r2_s;
    
    assign r1_s = $signed(rdata1);
    assign r2_s = $signed(rdata2);
    
    assign less_than = (!sign_select) ? (r1_s < r2_s) : (rdata1 < rdata2);
    assign equal     = (rdata1 == rdata2);
endmodule
