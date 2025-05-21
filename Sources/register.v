`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2025 01:21:04 PM
// Design Name: 
// Module Name: register
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


module register(
    input wire clk,
    input wire write_enable,
    input wire [4:0] rd, r1, r2,
    input wire [1:0] WBSel,
    input wire [31:0] PC, //not +4 need to +4 here
    input wire [31:0] ALU_out,
    input wire [31:0] dmem_out,
    output reg [31:0] rdata1, rdata2
    );
    
    //32 registers
    reg [31:0] RegData [31:0];
    wire [31:0] wdata;
    assign wdata = (WBSel == 2'b00) ? PC + 4 : 
                   (WBSel == 2'b01) ? ALU_out : dmem_out;
    
    //x0 is 0
    initial begin
        RegData[0] = 0;
    end
    
    //reads wdata into the destination register
    always @(posedge clk) begin
        rdata1 <= RegData[r1];
        rdata2 <= RegData[r2];
        if(write_enable && rd != 0 )
            RegData[rd] <= wdata;
    end 
endmodule
