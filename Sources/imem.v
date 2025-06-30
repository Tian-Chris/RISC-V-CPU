`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Chris Tian
// Module Name: imem
//////////////////////////////////////////////////////////////////////////////////

module imem(
    input  wire        rst,
    input  wire [31:0] PC,
    output reg  [31:0] inst,
    output reg  [4:0]  rd,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2
    );
    
    reg [7:0] inst_mem [0:9000];
    reg [31:0] EPC;
        
    always @(*) begin
        EPC = PC;
        if(PC[13] == 1) begin
            EPC[13] = 0;
            EPC[11] = 1;
        end
        `ifdef ENDIAN_BIG
            inst = {inst_mem[EPC], inst_mem[EPC + 1], inst_mem[EPC + 2], inst_mem[EPC + 3]};
        `else // default to little endian
            inst = {inst_mem[EPC + 3], inst_mem[EPC + 2], inst_mem[EPC + 1], inst_mem[EPC]};
        `endif

        rd  = inst[11:7];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
    end

endmodule
