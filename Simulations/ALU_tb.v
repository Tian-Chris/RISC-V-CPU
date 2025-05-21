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
    reg [31:0] a, b;
    reg [3:0] operation;
    wire [31:0] result;
    
    ALU dut (
    .a(a),
    .b(b),
    .operation(operation),
    .result(result)
    );
            
    initial begin
        a = 32'd12345;
        b = 32'd123;
        operation = 4'b0000; //add
        
        #5;
        a = 32'd12345;
        b = 32'd123;
        operation = 4'b0001; //sub
        
        #5;
        a = 32'd12345;
        b = 32'd123;
        operation = 4'b0010; //and
                
        #5;
        a = 32'd112345;
        b = 32'd123;
        operation = 4'b0011; //or
        
        #5;
        a = 32'd112345;
        b = 32'd123;
        operation = 4'b0100; //shift left
        
        #5;
        a = 32'd112345;
        b = 32'd123;
        operation = 4'b0101; //shift right
        
        #5;
        a = 32'd112345;
        b = 32'd123;
        operation = 4'b0110; //shift right arithmetic
        
        #5;
        a = 32'd112345;
        b = 32'd123;
        operation = 4'b0111; //less than
        
        #5;
        a = 32'd112345;
        b = 32'd123;
        operation = 4'b1000; //less than signed
    end
endmodule
