`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/21/2025 09:52:34 AM
// Design Name: 
// Module Name: imem
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


module imem( //swap this to wire
    input wire [31:0] PC,
    output reg [31:0] inst,
    output reg [4:0] rd,
    output reg [4:0] rs1,
    output reg [4:0] rs2
    );
    reg [31:0] inst_mem [127:0];
    
    initial begin
        $readmemh("test.mem", inst_mem);
    end
    
    always @(*)
    begin
        inst = inst_mem[PC[31:2]];
        rd   = inst_mem[PC[31:2]][11:7];
        rs1  = inst_mem[PC[31:2]][19:15];
        rs2  = inst_mem[PC[31:2]][24:20];
    end

endmodule
