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
    input wire [31:0] wdata,
    output wire [31:0] rdata1, rdata2
    );
    
    //32 registers
    reg [31:0] RegData [31:0];
    
    //x0 is 0
    initial begin
        RegData[0] = 0;
    end
    
    //reads wdata into the destination register
    always @(posedge clk) begin
        if(write_enable && rd != 0 )
            RegData[rd] <= wdata;
    end 
    
    //reads what is in the register r1 and r2
    assign rdata1 = RegData[r1];
    assign rdata2 = RegData[r2];
endmodule
