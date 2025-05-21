`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2025 12:11:09 PM
// Design Name: 
// Module Name: dmem_tb
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


`timescale 1ns / 1ps

module dmem_tb;
    reg clk;
    reg RW;
    reg [31:0] address;
    reg [31:0] wdata;
    wire [31:0] rdata;

    dmem uut (
        .clk(clk),
        .RW(RW),
        .address(address),
        .wdata(wdata),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        RW = 0;
        address = 0;
        wdata = 0;
        
        #10;
        RW = 1;
        address = 32'h00000000;
        wdata = 32'hABCDEF00;
        
        #10;
        address = 32'h00000004;
        wdata = 32'hFFFFFFFF;
        
        #10;
        address = 32'h00000008;
        wdata = 32'h12345678;
        
        #10;
        RW = 0;
        address = 32'h00000000;
        
        #10;
        address = 32'h00000004;
        
        #10;
        address = 32'h00000008;
        
        #10;
    end

endmodule
