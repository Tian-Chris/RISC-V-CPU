`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2025 10:03:59 AM
// Design Name: 
// Module Name: imem_tb
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


module imem_tb;
    reg [31:0] pc;
    wire [31:0] instr;
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;

    imem uut (
        .PC(pc),
        .inst(instr),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2)
    );

    initial begin
        pc = 0;

        #5;
        pc = pc + 4;
        #5;

        pc = pc + 4;
        #5;

        pc = pc + 4;

        #5 $finish;
    end
endmodule

