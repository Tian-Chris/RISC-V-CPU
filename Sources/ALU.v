`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/19/2025 12:48:01 PM
// Design Name: 
// Module Name: ALU
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


module ALU(
    input wire clk,
    input wire [31:0] rdata1, rdata2, PC, imm,
    input wire ASel, BSel,
    input wire [3:0] operation,
    input wire [31:0] MEMAlu,
    input wire [31:0] WBdmem,
    input wire [31:0] WBAlu,
    input wire [31:0] WBPC,   // not +4, need to +4 here
    input wire [1:0] WBSel,
    input wire [1:0] forwardA,
    input wire [1:0] forwardB,
    output reg [31:0] result //consider swapping to wire
    );
    `ifdef DEBUG_ALL
        `define DEBUG_ALU
    `endif
        
    wire [31:0] wdata;
    wire [31:0] aEX, bEX;
    wire [31:0] a, b;
    wire signed [31:0] a_s, b_s; //signed
    
    assign wdata = (WBSel == 2'b00) ? WBdmem : 
                   (WBSel == 2'b01) ? WBAlu : WBPC + 4;
      
    assign aEX   = ASel ? PC  : rdata1;
    assign bEX   = BSel ? imm : rdata2;
    assign a = forwardA[1] ? MEMAlu : (forwardA[0] ? wdata : aEX);
    assign b = forwardB[1] ? MEMAlu : (forwardB[0] ? wdata : bEX);
    assign a_s = $signed(a);
    assign b_s = $signed(b);

    //combinational
    always @(*) 
    begin
        case (operation)
            4'b0000: result = a + b;       //add
            4'b0001: result = a - b;       //subtract
            4'b0010: result = a & b;       //and
            4'b0011: result = a | b;       //or
            4'b0100: result = a ^ b;       //xor
            4'b0101: result = a << b[4:0];      //shift left
            4'b0110: result = a >> b[4:0];      //shift right
            4'b0111: result = a_s >>> b_s[4:0]; //shift right arithmetic
            4'b1000: result = (a < b);     //less than
            4'b1001: result = (a_s < b_s); //less than signed
            4'b1010: result = a;           //pass a
            4'b1011: result = b;           //pass b
            default: result = 32'hXXXXXXXX;
        endcase
    end
    
    always @(posedge clk) begin
        `ifdef DEBUG_ALU
            $display("===========  ALU  ===========");
            $display("operation   = %b", operation);
            $display("ASel        = %b | BSel        = %b", ASel, BSel);
            $display("PC          = %h", PC);
            $display("imm         = %h", imm);
            $display("rdata1      = %h", rdata1);
            $display("rdata2      = %h", rdata2);
            $display("aEX (raw)   = %h", aEX);
            $display("bEX (raw)   = %h", bEX);
            $display("forwardA    = %b | forwardB    = %b", forwardA, forwardB);
            $display("MEMAlu      = %h", MEMAlu);
            $display("WBdmem      = %h", WBdmem);
            $display("WBAlu       = %h", WBAlu);
            $display("WBPC + 4    = %h", WBPC + 4);
            $display("WBSel       = %b", WBSel);
            $display("wdata       = %h", wdata);
            $display("ALU Input a = %h", a);
            $display("ALU Input b = %h", b);
            $display("Result      = %h", result);
        `endif
    end
endmodule
