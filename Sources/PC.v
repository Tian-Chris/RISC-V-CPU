`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/20/2025 10:26:35 AM
// Design Name: 
// Module Name: PC
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


module PC(
    input clk,
    input wire [31:0] PC_ALU_input,
    input wire PC_select,
    output reg [31:0] PC
    );
    always @(posedge clk)
        begin
            if(PC_select)
                PC <= PC_ALU_input;
            else
                PC <= PC + 4;
        end
endmodule
