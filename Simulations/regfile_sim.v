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
    reg [31:0] wdata;
    reg we;
    wire [31:0] rdata1, rdata2;

    register dut (
        .clk(clk),
        .write_enable(we),
        .rd(rd),
        .r1(r1),
        .r2(r2),
        .wdata(wdata),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        we = 0;
        rd = 0;
        r1 = 5;
        r2 = 4;
        wdata = 0;

        #10;
        rd = 5;
        wdata = 32'd10;
        we = 1;

        #10;
        we = 0;        
        #10;
        rd = 4;
        wdata = 32'd13;
        we = 1;

        #10;
        we = 0;
        #10;
        $display("x5 = %d", rdata1);  // Expect 10
        $display("x4 = %d", rdata2);  // Expect 13

        #10;
        rd = 0;
        wdata = 32'd10;
        we = 1;

        #10;
        we = 0;
        r1 = 0;

        #10;
        $display("x0 = %d", rdata1);

        #10;
        $finish;
    end
endmodule
