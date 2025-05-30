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
   output wire [31:0] Out0, Out1, Out2, Out3, Out4, Out5, Out6, Out7, Out8, Out9, 
                      Out10, Out11, Out12, Out13, Out14, Out15, Out16, Out17, Out18,
                      Out19, Out20, Out21, Out22, Out23, Out24, Out25, Out26, Out27,
                      Out28, Out29, Out30, Out31, dmem_out
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
  
    //IF Stage Reg
    reg [31:0] IDinstruct;
    reg [31:0] IDPC;
    reg [4:0] IDrs1;
    reg [4:0] IDrs2;

    always @(posedge clk) begin
        IDinstruct <= instruction;
        IDPC <= pc;
        IDrs1 <= rs1;
        IDrs2 <= rs2;
    end
    
  // Immediate Generator
  imm_gen IMM (
    .imm_in(IDinstruct),
    .imm_sel(imm_gen_sel),
    .imm_out(imm)
  );

  // Datapath Controller
  datapath DP (
    .clk(clk),
    .instruct(IDinstruct),
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

    //WB Stage Reg
    reg [31:0] WBinstruct;
    reg [31:0] WBAlu;
    reg [31:0] WBPC;
    reg [31:0] WBdmem;
    
  // Register File
  register RF (
    .clk(clk),
    .write_enable(Reg_WEn),
    .rd(WBinstruct[11:7]),
    .r1(IDrs1),
    .r2(IDrs2),
    .WBSel(Reg_WBSel),
    .PC(WBPC),
    .ALU_out(WBAlu),
    .dmem_out(WBdmem),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .Out0(Out0), .Out1(Out1), .Out2(Out2), .Out3(Out3), 
    .Out4(Out4), .Out5(Out5), .Out6(Out6), .Out7(Out7), 
    .Out8(Out8), .Out9(Out9), .Out10(Out10), .Out11(Out11), 
    .Out12(Out12), .Out13(Out13), .Out14(Out14), .Out15(Out15), 
    .Out16(Out16), .Out17(Out17), .Out18(Out18), .Out19(Out19), 
    .Out20(Out20), .Out21(Out21), .Out22(Out22), .Out23(Out23), 
    .Out24(Out24), .Out25(Out25), .Out26(Out26), .Out27(Out27), 
    .Out28(Out28), .Out29(Out29), .Out30(Out30), .Out31(Out31)
  );

    //EX Stage Reg
    reg [31:0] EXinstruct;
    reg [31:0] EXPC;
    reg [31:0] EXrdata1;
    reg [31:0] EXrdata2;
    reg [31:0] EXimm;


    always @(posedge clk) begin
        EXinstruct <= IDinstruct;
        EXPC <= IDPC;
        EXrdata1 <= rdata1;
        EXrdata2 <= rdata2;
        EXimm <= imm;
    end
  
  // ALU
  ALU ALU (
    .rdata1(EXrdata1),
    .rdata2(EXrdata2),
    .PC(EXPC),
    .imm(EXimm),
    .ASel(ALU_ASel),
    .BSel(ALU_BSel),
    .operation(ALU_Sel),
    .result(alu_out)
  );

  // Branch Comparator
  branch_comp COMP (
    .sign_select(branch_signed),
    .rdata1(EXrdata1),
    .rdata2(EXrdata2),
    .equal(brEq),
    .less_than(brLt)
  );


    //MEM Stage Reg
    reg [31:0] MEMinstruct;
    reg [31:0] MEMAlu;
    reg [31:0] MEMrdata2;
    reg [31:0] MEMPC;

    always @(posedge clk) begin
        MEMinstruct <= EXinstruct;
        MEMPC <= EXPC;
        MEMrdata2 <= EXrdata2;
        MEMAlu <= alu_out;
    end
    
  // Data Memory
  dmem DMEM (
    .clk(clk),
    .RW(dmemRW),
    .funct3(funct3),
    .address(MEMAlu),
    .wdata(MEMrdata2),
    .rdata(dmem_out),
    .dmem_out(dmem_out)
  );

    //WB Stage Reg
    always @(posedge clk) begin
        WBPC <= MEMPC;
        WBdmem <= dmem_out;
        WBAlu <= MEMAlu;
        WBinstruct <= MEMinstruct;
    end
endmodule


//00500093
//addi x1 x0 5
//addi x2 x1 10