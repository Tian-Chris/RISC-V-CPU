`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/21/2025 12:00:38 PM
// Design Name: 
// Module Name: dmem
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


module dmem(
    input wire clk,
    input wire RW, //1 = write 0 = read
    input wire [31:0] address,
    input wire [31:0] wdata,
    output reg [31:0] rdata
    );
    
    reg [31:0] dmem [127:0];

    initial begin
        dmem[0] <= 0;
        rdata <= 0;
    end
    
    always @(posedge clk)
    begin
        if(RW) begin
            dmem[address[31:2]] <= wdata;
            rdata <= rdata;
        end
        else
            rdata <= dmem[address[31:2]];
    end
endmodule
