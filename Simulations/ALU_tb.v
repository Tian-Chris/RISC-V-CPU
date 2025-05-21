`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2025 11:11:47 AM
// Design Name: 
// Module Name: ALU_tb
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
module ALU_tb;

    reg [31:0] rdata1, rdata2, PC, imm;
    reg ASel, BSel;
    reg [3:0] operation;
    
    wire [31:0] result;

    ALU uut (
        .rdata1(rdata1),
        .rdata2(rdata2),
        .PC(PC),
        .imm(imm),
        .ASel(ASel),
        .BSel(BSel),
        .operation(operation),
        .result(result)
    );

    initial begin
        rdata1 = 32'd12345;
        rdata2 = 32'd123;
        PC     = 32'd100;
        imm    = 32'd4;

        // add
        ASel = 0; BSel = 0;
        operation = 4'b0000;
        #10;

        // sub
        operation = 4'b0001;
        #10;

        // and
        operation = 4'b0010;
        #10;

        // or
        operation = 4'b0011;
        #10;

        // shift left
        rdata2 = 32'd5;
        operation = 4'b0100;
        #10;

        // shift right
        operation = 4'b0101;
        #10;

        // asr
        rdata1 = 32'hf0000000;
        operation = 4'b0110;
        #10;

        //less than
        rdata1 = 32'hffffffff;
        rdata2 = 32'h0fffffff;
        operation = 4'b0111;
        #10;

        rdata1 = 32'h0fffffff;
        rdata2 = 32'hffffffff;
        operation = 4'b0111;
        #10;
        
       
        // less than signed
        operation = 4'b1000;
        #10;
        
        rdata1 = 32'hffffffff;
        rdata2 = 32'h0fffffff;
        #10;
        
        // pc + imm
        ASel = 1; BSel = 1;
        operation = 4'b0000;
        #10;
    end
endmodule
