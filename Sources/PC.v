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
    input              clk,
    input              rst,
    input  wire [31:0] PC_ALU_input,
    input  wire        PC_select,
    input  wire [3:0]  hazard_signal,
    input  wire [31:0] PC_Jump, //for early jump/branch
    input  wire        jump_taken, //for early jump/branch
    input  wire        mispredict,
    input  wire [31:0] PC_savedMEM,
    output reg  [31:0] PC,
    input  wire        EX_csr_branch_signal,
    input  wire [31:0] EX_csr_branch_address,
    input  wire        fence
    );
    `ifdef DEBUG_ALL
        `define DEBUG_PC
    `endif
    initial begin
        PC <= 0;
    end
    always @(posedge clk)
        begin
            `ifdef DEBUG
                $display("");
                $display("==========");
                $display("PC: %h", PC);
            `endif 
            `ifdef DEBUG_PC
                $display("===========  PC  ===========");
                $display("PC ==> PC: %h | EXBS: %b | EXBA: %h | hazard_signal: %b | PCSEL: %b | jump_taken: %h | mispredict: %h | PC_savedMEM: %h", PC, EX_csr_branch_signal, EX_csr_branch_address, hazard_signal, PC_select, jump_taken, mispredict, PC_savedMEM);
            `endif
            if(rst)
                PC <= 0;
            else begin
                if(EX_csr_branch_signal)
                    PC <= EX_csr_branch_address;
                else if(PC_select) begin
                    if(mispredict)
                        PC <= PC_savedMEM + 4;
                    else
                        PC <= PC_ALU_input;
                end
                else if(hazard_signal != `STALL_EARLY && hazard_signal != `STALL_MMU) begin
                    if(jump_taken != 0)
                        PC <= PC + PC_Jump - 4;
                    else
                        if(fence)
                            PC <= PC;
                        else
                            PC <= PC + 4;
                end
            end
        end
endmodule
