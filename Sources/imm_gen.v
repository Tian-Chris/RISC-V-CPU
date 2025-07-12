`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2025 09:52:34 AM
// Design Name: 
// Module Name: imm_gen
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


module imm_gen( //swap to wire
    input wire [31:0] imm_in,
    input wire [2:0] imm_sel,
    input wire clk,
    output reg [31:0] imm_out
    );
    reg [31:0] prev_imm;
    reg [2:0]  prev_sel;
    
    always @(*) begin
        case (imm_sel)
            3'b000:  // I-type
                imm_out = {{20{imm_in[31]}}, imm_in[31:20]};
                
            3'b001:  // I*-type
                imm_out = {27'b0, imm_in[24:20]};
                
            3'b010:  // S-type
                imm_out = {{20{imm_in[31]}}, imm_in[31:25], imm_in[11:7]};
                
            3'b011:  // B-type
                imm_out = {{19{imm_in[31]}}, imm_in[31], imm_in[7], imm_in[30:25], imm_in[11:8], 1'b0};
                
            3'b100:  // U-type
                imm_out = {imm_in[31:12], 12'b0};
                
            3'b101:  // J-type
                imm_out = {{11{imm_in[31]}}, imm_in[31], imm_in[19:12], imm_in[20], imm_in[30:21], 1'b0};
        
            default:
                imm_out = 32'hXXXXXXXX;
        endcase

    end
    always @(posedge clk) begin
        
        $display("imm_in: %h, imm_sel: %h , imm_out: %h", imm_in, imm_sel, imm_out);
    end
endmodule
