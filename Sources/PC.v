`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/20/2025 10:26:35 AM
// Design Name: 
// Module Name: PC
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


module PC(
    input  clk,
    input  wire [31:0] PC_ALU_input,
    input  wire PC_select,
    input  wire stall,
    input  wire [31:0] PC_Jump, //for early jump/branch
    input  wire jump_taken, //for early jump/branch
    input  wire mispredict,
    input  wire [31:0] PC_savedMEM,
    output reg  [31:0] PC,
    input  wire        EX_csr_branch_signal,
    input  wire [31:0] EX_csr_branch_address
    );
    
    initial begin
        PC <= 0;
    end
    always @(posedge clk)
        begin
            if(EX_csr_branch_signal)
                PC <= EX_csr_branch_address;
            else if(PC_select) begin
                if(mispredict)
                    PC <= PC_savedMEM + 4;
                else
                    PC <= PC_ALU_input;
            end
            else if(!stall) begin
                if(jump_taken != 0)
                    PC <= PC + PC_Jump - 4;
                else
                    PC <= PC + 4;
            end
            $display("PC ==> PC: %h | EXBS: %b | EXBA: %h | Stall: %b | PCSEL: %b | jump_taken: %h | mispredict: %h | PC_savedMEM: %h", PC, EX_csr_branch_signal, EX_csr_branch_address, stall, PC_select, jump_taken, mispredict, PC_savedMEM);
        end
endmodule
