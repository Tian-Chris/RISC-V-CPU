`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/23/2025 10:19:14 AM
// Design Name: 
// Module Name: top
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

module cpu_top (
  input wire clk,
  input wire reset,

  // Debug outputs
  output wire [31:0] pc,
  output wire [31:0] instruction,
  output wire [31:0] alu_out,
  output wire [31:0] imm,
  output wire [31:0] rdata1,
  output wire [31:0] rdata2,
  output wire brEq,
  output wire brLt,
  output wire Reg_WEn,
  output wire PCSel,
  
   //output reg
   output wire [31:0] Out0, Out1, Out2, Out3, Out4, dmem_out
   );

  wire [4:0] rs1, rs2, rd;
  wire branch_signed, ALU_BSel, ALU_ASel, dmemRW;
  wire [2:0] funct3, imm_gen_sel;
  wire [3:0] ALU_Sel;
  wire [1:0] Reg_WBSel;

  // Program Counter
  PC PC (
    .clk(clk),
    .PC_ALU_input(alu_out),
    .PC_select(PCSel),
    .PC(pc)
  );

  // Instruction Memory
  imem IMEM (
    .PC(pc),
    .inst(instruction),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2)
  );

  // Immediate Generator
  imm_gen IMM (
    .imm_in(instruction),
    .imm_sel(imm_gen_sel),
    .imm_out(imm)
  );

  // Datapath Controller
  datapath DP (
    .instruct(instruction),
    .brEq(brEq),
    .brLt(brLt),
    .funct3(funct3),
    .PCSel(PCSel),
    .Reg_WEn(Reg_WEn),
    .imm_gen_sel(imm_gen_sel),
    .branch_signed(branch_signed),
    .ALU_BSel(ALU_BSel),
    .ALU_ASel(ALU_ASel),
    .ALU_Sel(ALU_Sel),
    .dmemRW(dmemRW),
    .Reg_WBSel(Reg_WBSel)
  );

  // Register File
  register RF (
    .clk(clk),
    .write_enable(Reg_WEn),
    .rd(rd),
    .r1(rs1),
    .r2(rs2),
    .WBSel(Reg_WBSel),
    .PC(pc),
    .ALU_out(alu_out),
    .dmem_out(dmem_out),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .Out0(Out0),
    .Out1(Out1),
    .Out2(Out2),
    .Out3(Out3),
    .Out4(Out4)
  );

  // ALU
  ALU ALU (
    .rdata1(rdata1),
    .rdata2(rdata2),
    .PC(pc),
    .imm(imm),
    .ASel(ALU_ASel),
    .BSel(ALU_BSel),
    .operation(ALU_Sel),
    .result(alu_out)
  );

  // Branch Comparator
  branch_comp COMP (
    .sign_select(branch_signed),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .equal(brEq),
    .less_than(brLt)
  );

  // Data Memory
  dmem DMEM (
    .clk(clk),
    .RW(dmemRW),
    .funct3(funct3),
    .address(alu_out),
    .wdata(rdata2),
    .rdata(dmem_out),
    .dmem_out(dmem_out)
  );

endmodule


//00500093
//addi x1 x0 5
//addi x2 x1 10