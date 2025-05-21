`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/20/2025 10:42:57 AM
// Design Name: 
// Module Name: regfile_sim
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
module register_tb; 

    reg clk;
    reg [4:0] r1, r2, rd;
    reg [1:0] WBSel;
    reg [31:0] PC;
    reg [31:0] ALU_out;
    reg [31:0] dmem_out;
    reg we;
    wire [31:0] rdata1, rdata2;

    // DUT instance
    register dut (
        .clk(clk),
        .write_enable(we),
        .rd(rd),
        .r1(r1),
        .r2(r2),
        .WBSel(WBSel),
        .PC(PC),
        .ALU_out(ALU_out),
        .dmem_out(dmem_out),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        we = 0;
        rd = 0;
        r1 = 0;
        r2 = 0;
        WBSel = 2'b00;
        PC = 0;
        ALU_out = 0;
        dmem_out = 0;

        // ALU: 10 to x5
        #10;
        rd = 5;
        ALU_out = 32'd10;
        WBSel = 2'b01;
        we = 1;
        #10;
        we = 0;

        // dmem: 13 to x4
        rd = 4;
        dmem_out = 32'd13;
        WBSel = 2'b10;
        we = 1;
        #10;
        we = 0;
        
        // PC: 5 to x3 (should result in 9)
        rd = 3;
        PC = 32'd5;
        WBSel = 2'b00;
        we = 1;
        #10;
        we = 0;

        r1 = 5;
        r2 = 4;
        #10;
        r1 = 3;
        
        #10;
        rd = 0;
        ALU_out = 32'd10;
        WBSel = 2'b01;
        we = 1;
        #10;
        we = 0;

        r1 = 0;
        #10;
    end
endmodule

