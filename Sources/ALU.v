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
    input wire [31:0] a, b,
    input wire [3:0] operation,
    output reg [31:0] result
    );
    
    //combinational
    always @(*) 
    begin
        case (operation)
            4'b0000: result = a + b;    //add
            4'b0001: result = a - b;    //subtract
            4'b0010: result = a & b;   //and
            4'b0011: result = a | b;   //or
            4'b0100: result = a << b;   //shift left
            4'b0101: result = a >> b;   //shift right
            4'b0110: result = a >>> b;  //shift right arithmetic
            4'b0111: result = (a < b);  //less than
            4'b1000: result = (a < b) || a[31] & ~b[31] || (~a[31] & ~b[31] & a < b) || (a[31] & b[31] & a > b);   //less than signed
            default: result = 32'hXXXXXXXX;
            
        endcase
    end
endmodule
