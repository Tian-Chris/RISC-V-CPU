`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2025 10:30:30 AM
// Design Name: 
// Module Name: imm_gen_tb
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

module imm_gen_tb;
    reg [31:0] imm_in;
    reg [2:0] imm_sel;
    wire [31:0] imm_out;

    imm_gen uut (
        .imm_in(imm_in),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    initial begin        
        // I-type:
        imm_in = 32'b111111111011_00000_000_00000_0000000; // 111111111011 = -5
        imm_sel = 3'b000;
        #10;

        // I-type
        imm_in = 32'b0000000_00100_00000_000_00000_0000000;
        imm_sel = 3'b001;
        #10;

        // S-type:
        imm_in = 32'b1111111_00000_00000_000_11100_0000000;  
        imm_sel = 3'b010;
        #10;

        // B-type:
        imm_in = 32'b0010100_00000_00000_000_00110_0000000;
        imm_sel = 3'b011; //h286
        #10;

        // U-type:
        imm_in = 32'b00010010001101000101_00000_0000000;
        imm_sel = 3'b100; //h12345000
        #10;

        // J-type:
        imm_in = 32'b10101010101010101010_00000_0000000; 
        imm_sel = 3'b101; //hfffaa2aa
        #10;
    end

endmodule
