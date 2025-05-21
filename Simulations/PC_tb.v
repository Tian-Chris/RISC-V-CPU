`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2025 09:48:09 AM
// Design Name: 
// Module Name: PC_tb
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

module PC_tb;

    reg clk;
    reg [31:0] PC_ALU_input;
    reg PC_select;
    wire [31:0] PC;

    // Instantiate the PC module
    PC uut (
        .clk(clk),
        .PC_ALU_input(PC_ALU_input),
        .PC_select(PC_select),
        .PC(PC)
    );

    // Generate clock (10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initial values
        PC_select = 0;
        PC_ALU_input = 32'h00000000;

        // Wait a few cycles with PC_select = 0 (increment)
        #20;

        // Jump to address 0xA0
        PC_select = 1;
        PC_ALU_input = 32'h000000A0;
        #10;

        // Back to increment mode
        PC_select = 0;
        #20;

        // Jump to 0x200
        PC_select = 1;
        PC_ALU_input = 32'h00000200;
        #10;

        // Finish simulation
        #10;
        $finish;
    end
endmodule

