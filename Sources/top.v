`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Chris Tian
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
  input  wire        clk,
  input  wire        rst,
  output wire        ecall,
  output wire [31:0] csr_satpo,
  input  wire        rx_line,
  output wire        tx_line
  // Debug outputs
  `ifdef DEBUG
    , output wire [31:0] pco, instructiono, alu_outo, immo, rdata1o, rdata2o, Out0, 
                       Out1, Out2, Out3, Out4, Out5, Out6, Out7, Out8, Out9, Out10, Out11, 
                       Out12, Out13, Out14, Out15, Out16, Out17, Out18, Out19, Out20, Out21, 
                       Out22, Out23, Out24, Out25, Out26, Out27, Out28, Out29, Out30, Out31,
   output wire [1:0] privo
  `endif
   );
   `include "inst_defs.v"
   `include "csr_defs.v"

    wire fence;
    wire [31:0] pc;
    wire [31:0] alu_out;
    wire [31:0] imm;
    wire [31:0] rdata1;
    wire [31:0] rdata2;
    wire        brEq;
    wire        brLt;
    wire        Reg_WEn;
    wire        PCSel;
    wire [1:0]  Reg_WBSelID;
    wire [1:0]  Reg_WBSelEX;
    wire [4:0]  rs1, rs2, rd;
    wire        branch_signed, ALU_BSel, ALU_ASel, dmemRW;
    wire [2:0]  funct3, imm_gen_sel;
    wire [3:0]  ALU_Sel;
    wire [1:0]  Reg_WBSel, forwardA, forwardB, forwardDmem, forwardBranchA, forwardBranchB;
    
    //mmu
    wire  [31:0] csr_satp;
    wire        sstatus_sum;
    wire        instr_fault_mmu_IMEM;
    wire        load_fault_mmu_IMEM;
    wire        store_fault_mmu_IMEM;
    wire [31:0] faulting_va_IMEM;
    wire [31:0] faulting_va_IMEM_ID;
    wire        access_is_load_IMEM = 0;
    wire        access_is_store_IMEM = 0;
    wire        access_is_inst_IMEM = 1;
    //mmudmem
    wire        instr_fault_mmu_DMEM;
    wire        load_fault_mmu_DMEM;
    wire        store_fault_mmu_DMEM;
    wire [31:0] faulting_va_DMEM;
    wire        access_is_inst_DMEM = 0;
    wire [3:0]  hazard_signal;
    
    //ID Stage Reg
    wire  [1:0]  priv;
    wire  [31:0] IDinstruct;
    wire  [31:0] IDPC;
    wire  [4:0]  IDrs1;
    wire  [4:0]  IDrs2;
    wire  [4:0]  IDrd;
    wire         EXmemRead;
    wire  [31:0] IDinstCSR;
    wire         access_is_load_ID;
    wire         access_is_store_ID;
    reg  [1:0]  priv_ID;
    
    //exception
    wire  [4:0]  trapID;
    wire         pc_misaligned       = (pc[1:0] != 2'b00);
    wire         invalid_inst;      // the signal
    wire  [31:0] faulting_inst;     // the inst
    wire  [31:0] faulting_inst_ID;  // the inst in id

    //interrupt
    wire mtip;
    wire msip;
    wire meip;
    wire stall_IMEM;
    wire stall_DMEM;
    
    //early jump/branch
    wire        jump_early;
    wire        branch_early;
    wire [31:0] PC_Jump;
    wire        jump_taken;
    //branch
    wire        branch_resolved;
    wire        actual_taken;
    wire [2:0]  pht_index;
    wire        mispredict;
    wire [31:0] PC_saved;

    //EX Stage Reg
    wire [31:0] EXinstruct;
    wire [31:0] EXPC;
    wire [31:0] EXrdata1;
    wire [31:0] EXrdata2;
    wire [31:0] EXimm;
    wire [4:0]  EXrd;
    reg  [31:0] DMEMPreClockData;
    reg  [31:0] wdata;
    wire        EXjump_taken;
    wire [2:0]  pht_indexEX;
    wire [31:0] PC_savedEX;
    wire [31:0] EXinstCSR;
    wire        EX_csr_reg_en;
    wire        EX_csr_branch_signal;
    wire [31:0] EX_csr_branch_address;
    wire        access_is_load_EX;
    wire        access_is_store_EX;
    reg  [1:0]  priv_EX;

    //MEM Stage Reg
    wire [31:0] MEMinstruct;
    wire [31:0] MEMAlu;
    wire [31:0] MEMrdata2;
    wire [31:0] MEMPC;
    wire [4:0]  MEMrd;        
    wire        MEMjump_taken;
    wire [2:0]  pht_indexMEM;
    wire [31:0] PC_savedMEM;
    wire [31:0] MEM_csr_rresult; //result of read
    wire        MEM_csr_reg_en;
    wire [31:0] MEM_csr_data_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    wire [31:0] MEM_csr_addr_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    wire        access_is_load_MEM;
    wire        access_is_store_MEM;
    wire [31:0] dmem_out;
    reg  [1:0]  priv_MEM;

    //WB Stage Reg
    wire [31:0] WBinstruct;
    wire [31:0] WBAlu;
    wire [31:0] WBPC;
    wire [31:0] WBdmem;
    wire [4:0]  WBrd;
    wire        WB_csr_reg_en;
    wire        WB_csr_wben;
    wire [11:0] WB_csr_wbaddr;   //address written
    wire [31:0] WB_csr_wbdata;   //data written
    wire [31:0] WB_csr_rresult; //result of read
    wire [31:0] WB_csr_data_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    wire [31:0] WB_csr_addr_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    
    //debug
    assign csr_satpo = csr_satp;
    `ifdef DEBUG
      assign pco          = IDPC;
      assign instructiono = IDinstruct; 
      assign alu_outo     = alu_out;
      assign immo         = imm;
      assign rdata1o      = rdata1;
      assign rdata2o      = rdata2;
      assign privo        = priv;
    `endif 
    
    always @(posedge clk) begin
        `ifdef DEBUG_TOP
        $display("========== TOP ===========");
        $display("EX_IMM: %h, imm: %h", EXimm, imm);
        $display(
        "EXPC: %h, IDPC: %h | EXrdata1: %h, rdata1: %h | EXrdata2: %h, rdata2: %h | EXimm: %h, imm: %h | EXrd: %h, IDrd: %h |",
        EXPC, IDPC,
        EXrdata1, rdata1,
        EXrdata2, rdata2,
        EXimm, imm,
        EXrd, IDrd
    );
    $display(
        "EXjump_taken: %b, jump_taken: %b | pht_indexEX: %h, pht_index: %h | PC_savedEX: %h, PC_saved: %h |",
        EXjump_taken, jump_taken,
        pht_indexEX, pht_index,
        PC_savedEX, PC_saved
    );
    $display(
        "access_is_load_EX: %b, access_is_load_ID: %b | access_is_store_EX: %b, access_is_store_ID: %b",
        access_is_load_EX, access_is_load_ID,
        access_is_store_EX, access_is_store_ID
    );
    $display("Alu: %h", alu_out);
        $display(
        "MEMPC: %h, MEMrdata2: %h | MEMAlu: %h, MEMrd: %d\nMEMjump_taken: %b, pht_indexMEM: %h | PC_savedMEM: %h, MEM_csr_reg_en: %b\naccess_is_load_MEM: %b, access_is_store_MEM: %b",
        MEMPC, MEMrdata2,
        MEMAlu, MEMrd,
        MEMjump_taken, pht_indexMEM,
        PC_savedMEM, MEM_csr_reg_en,
        access_is_load_MEM, access_is_store_MEM
    );
    `endif 
        if(rst) begin
            priv_ID      <= `PRIV_MACHINE;
            priv_EX      <= `PRIV_MACHINE;
            priv_MEM     <= `PRIV_MACHINE;
        end
        else if(hazard_signal != `STALL_MMU) begin
            priv_ID      <= priv;
            priv_EX      <= priv_ID;
            priv_MEM     <= priv_EX;
        end
    end

    // ===========
    //    ID-EX
    // ===========
    localparam EXINST_WIDTH = 32 + 32; 
    wire [EXINST_WIDTH-1:0]  EXINST = {IDinstruct, IDinstCSR};
    wire [EXINST_WIDTH-1:0]  EXINST_OUT;
    Pipe #(.STAGE(`STAGE_EX), .WIDTH(EXINST_WIDTH), .RESET_VALUE(`INST_NOP)) PIPE_INST_EX (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(EXINST), .out_data(EXINST_OUT)
        );
    assign {EXinstruct, EXinstCSR} = EXINST_OUT; 
    
    localparam EX_WIDTH = 32 + 32 + 32 + 32 + 5 + 1 + 3 + 32 + 1 + 1; 
    wire [EX_WIDTH-1:0]  EX = {IDPC, rdata1, rdata2, imm, IDrd, jump_taken, pht_index, PC_saved, access_is_load_ID, access_is_store_ID};
    wire [EX_WIDTH-1:0]  EX_OUT;
    Pipe #(.STAGE(`STAGE_EX), .WIDTH(EX_WIDTH)) PIPE_EX (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(EX), .out_data(EX_OUT)
        );
    assign {EXPC, EXrdata1, EXrdata2, EXimm, EXrd, EXjump_taken, pht_indexEX, PC_savedEX, access_is_load_EX, access_is_store_EX} = EX_OUT; 
        
    //forwarding into dmem
    always @(*) begin
        wdata = (WB_csr_reg_en) ? WB_csr_rresult : 
                (Reg_WBSel == 2'b00) ? WBdmem : 
                (Reg_WBSel == 2'b01) ? WBAlu : WBPC + 4;
        DMEMPreClockData = forwardDmem[1] ? MEMAlu : (forwardDmem[0] ? wdata : EXrdata2);
    end

    // ===========
    //    EX-MEM
    // ===========
    Pipe #(.STAGE(`STAGE_MEM), .WIDTH(32), .RESET_VALUE(`INST_NOP)) PIPE_MEM_INST (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(EXinstruct), .out_data(MEMinstruct)
        );
    
    localparam MEM_WIDTH = 32 + 32 + 32 + 5 + 1 + 3 + 32 + 1 + 1 + 1;
    wire [MEM_WIDTH-1:0]  MEM = {EXPC, DMEMPreClockData, alu_out, EXrd, EXjump_taken, pht_indexEX, PC_savedEX, EX_csr_reg_en, access_is_load_EX, access_is_store_EX};
    wire [MEM_WIDTH-1:0]  MEM_OUT;
    Pipe #(.STAGE(`STAGE_MEM), .WIDTH(MEM_WIDTH)) PIPE_MEM (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(MEM), .out_data(MEM_OUT)
        );
    assign {MEMPC, MEMrdata2, MEMAlu, MEMrd, MEMjump_taken, pht_indexMEM, PC_savedMEM, MEM_csr_reg_en, access_is_load_MEM, access_is_store_MEM} = MEM_OUT; 
        
    // ===========
    //    MEM-WB
    // ===========
    Pipe #(.STAGE(`STAGE_WB), .WIDTH(32), .RESET_VALUE(`INST_NOP)) PIPE_WB_INST (
    .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(MEMinstruct), .out_data(WBinstruct)
    );

    localparam WB_WIDTH = 32 + 32 + 32 + 5 + 32 + 1 + 32 + 32;
    wire [WB_WIDTH-1:0]  WB = {MEMPC, dmem_out, MEMAlu, MEMrd, MEM_csr_rresult, MEM_csr_reg_en, MEM_csr_data_to_wb, MEM_csr_addr_to_wb};
    wire [WB_WIDTH-1:0]  WB_OUT;
    Pipe #(.STAGE(`STAGE_WB), .WIDTH(WB_WIDTH)) PIPE_WB (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(WB), .out_data(WB_OUT)
        );
    assign {WBPC, WBdmem, WBAlu, WBrd, WB_csr_rresult, WB_csr_reg_en, WB_csr_data_to_wb, WB_csr_addr_to_wb} = WB_OUT; 

  //Validity bit for MMU unit
  wire valid = 1;
  wire validID;
  wire validEX;
  wire validMEM;
  wire validWB;
  Pipe #(.STAGE(`STAGE_ID), .WIDTH(1)) PIPE_VID (
    .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(valid), .out_data(validID)
    );
  Pipe #(.STAGE(`STAGE_EX), .WIDTH(1)) PIPE_VEX (
    .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(validID), .out_data(validEX)
    );
  Pipe #(.STAGE(`STAGE_MEM), .WIDTH(1)) PIPE_VMEM (
    .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(validEX), .out_data(validMEM)
    );
  Pipe #(.STAGE(`STAGE_WB), .WIDTH(1)) PIPE_VWB (
  .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(validMEM), .out_data(validWB)
  );
  // ===========
  //   Modules
  // ===========
  // Program Counter
  PC PC (
    .clk(clk),
    .rst(rst),
    .PC_ALU_input(MEMAlu),
    .PC_select(PCSel),
    .PC_Jump(PC_Jump),
    .jump_taken(jump_taken),
    .PC(pc),
    .fence(fence),
    .PC_savedMEM(PC_savedMEM),
    .mispredict(mispredict),
    .hazard_signal(hazard_signal),
    .EX_csr_branch_signal(EX_csr_branch_signal),
    .EX_csr_branch_address(EX_csr_branch_address)
  );

  // Unified Memory
  MEM_unit MEM (
    //IMEM
    .rst(rst),
    .hazard_signal(hazard_signal),

    //IMEM Decode
    .pc(pc),
    .IDinstruct_o(IDinstruct),
    .IDPC_o(IDPC),
    .IDrs1_o(IDrs1),
    .IDrs2_o(IDrs2),
    .IDrd_o(IDrd),
    .IDinstCSR_o(IDinstCSR),
    .fence_active(fence),
    .invalid_inst(invalid_inst),
    .faulting_inst(faulting_inst_ID),
    .access_is_load_ID(access_is_load_ID),
    .access_is_store_ID(access_is_store_ID),
    .ecall(ecall),

    //DMEM
    .clk(clk),
    .RW(dmemRW),
    .funct3(funct3),
    .wdata(MEMrdata2),
    .rdata(dmem_out),
    .WB_csr_reg_en(WB_csr_reg_en),
    .WB_csr_rresult(WB_csr_rresult),

    //MMU
    .csr_satp(csr_satp),
    .sstatus_sum(sstatus_sum), 

    //CLINT AND UART
    .mtip(mtip),
    .msip(msip),
    .meip(meip),
    .rx_line(rx_line),
    .tx_line(tx_line),

    //IMEM
    .priv_IMEM(priv_ID),
    .VPC_IMEM(pc), 
    .validID(valid), // IMEM is IF stage not ID
    .access_is_load_IMEM(access_is_load_IMEM),
    .access_is_store_IMEM(access_is_store_IMEM),
    .access_is_inst_IMEM(access_is_inst_IMEM),
    .instr_fault_mmu_IMEM(instr_fault_mmu_IMEM),
    .load_fault_mmu_IMEM(load_fault_mmu_IMEM),
    .store_fault_mmu_IMEM(store_fault_mmu_IMEM),
    .faulting_va_IMEM(faulting_va_IMEM_ID),
    .stall_IMEM(stall_IMEM),

    //DMEM
    .priv_DMEM(priv_MEM),
    .VPC_DMEM(MEMAlu), 
    .validMEM(validMEM),
    .access_is_load_DMEM(access_is_load_MEM),
    .access_is_store_DMEM(access_is_store_MEM),
    .access_is_inst_DMEM(access_is_inst_DMEM),
    .instr_fault_mmu_DMEM(instr_fault_mmu_DMEM),
    .load_fault_mmu_DMEM(load_fault_mmu_DMEM),
    .store_fault_mmu_DMEM(store_fault_mmu_DMEM),
    .faulting_va_DMEM(faulting_va_DMEM),
    .stall_DMEM(stall_DMEM)
    );

  imm_gen IMM (
    .clk(clk),
    .imm_in(IDinstruct),
    .imm_sel(imm_gen_sel),
    .imm_out(imm)
  );
  
  //early jump/branch predictor handler
  jump_branch_unit BP (
    .clk(clk),
    .rst(rst),
    .jump_early(jump_early),
    .branch_early(branch_early),
    .immID(imm),
    .pc(IDPC),
    .branch_resolved(branch_resolved),
    .actual_taken(actual_taken),
    .pht_index(pht_index),
    .pht_indexMEM(pht_indexMEM),
    .PC_Jump(PC_Jump),
    .jump_taken(jump_taken),
    .PC_saved(PC_saved)
  );
  
  datapath DP (
    .clk(clk),
    .rst(rst),
    .instruct(IDinstruct),
    .EXinstCSR(EXinstCSR),
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
    .Reg_WBSel(Reg_WBSel),
    .MEMrd(MEMrd),
    .WBrd(WBrd),
    .forwardA(forwardA),
    .forwardB(forwardB),
    .forwardDmem(forwardDmem),
    .forwardBranchA(forwardBranchA),
    .forwardBranchB(forwardBranchB),
    .Reg_WBSelID(Reg_WBSelID),
    .Reg_WBSelEX(Reg_WBSelEX),
    .jump_taken(MEMjump_taken),
    .jump_early(jump_early),
    .branch_early(branch_early),
    .mispredict(mispredict),
    .hazard_signal(hazard_signal),
    .EXmemRead(EXmemRead),
    .branch_resolved(branch_resolved),
    .actual_taken(actual_taken)
  );    

  register RF (
    .clk(clk),
    .rst(rst),
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
    .WB_csr_reg_en(WB_csr_reg_en),
    .WB_csr_wben(WB_csr_wben),
    .WB_csr_wbaddr(WB_csr_wbaddr),   //address written
    .WB_csr_wbdata(WB_csr_wbdata),   //data written
    .WB_csr_rresult(WB_csr_rresult), //result of read
    .WB_csr_data_to_wb(WB_csr_data_to_wb),  //csr_data_to_wb -> WB -> csr_wdata 
    .WB_csr_addr_to_wb(WB_csr_addr_to_wb)  //csr_data_to_wb -> WB -> csr_wdata 
    
    `ifdef DEBUG
      , .Out0(Out0), .Out1(Out1), .Out2(Out2), .Out3(Out3), 
      .Out4(Out4), .Out5(Out5), .Out6(Out6), .Out7(Out7), 
      .Out8(Out8), .Out9(Out9), .Out10(Out10), .Out11(Out11), 
      .Out12(Out12), .Out13(Out13), .Out14(Out14), .Out15(Out15), 
      .Out16(Out16), .Out17(Out17), .Out18(Out18), .Out19(Out19), 
      .Out20(Out20), .Out21(Out21), .Out22(Out22), .Out23(Out23), 
      .Out24(Out24), .Out25(Out25), .Out26(Out26), .Out27(Out27), 
      .Out28(Out28), .Out29(Out29), .Out30(Out30), .Out31(Out31)
    `endif
  );

  csr_handler CSR (
  .clk(clk),
  .rst(rst),
  .csr_trapID(trapID),
  .csr_trapPC(MEMPC),
  .faulting_inst(faulting_inst),
  .faulting_va_IMEM(faulting_va_IMEM),
  .faulting_va_DMEM(faulting_va_DMEM),
  .hazard_signal(hazard_signal),
  .csr_inst(EXinstCSR),
  .csr_rs1(EXrdata1),
  .csr_reg_en(EX_csr_reg_en),
  .csr_wben(WB_csr_wben),
  .csr_wbaddr(WB_csr_wbaddr),   //address written
  .csr_wbdata(WB_csr_wbdata),   //data written
  .csr_rresult(MEM_csr_rresult), //result of read
  .csr_data_to_wb(MEM_csr_data_to_wb),  //csr_data_to_wb -> WB -> csr_wdata 
  .csr_addr_to_wb(MEM_csr_addr_to_wb),  //csr_data_to_wb -> WB -> csr_wdata 
  .csr_branch_signal(EX_csr_branch_signal),
  .csr_branch_address(EX_csr_branch_address),
  .MEMAlu(MEMAlu),
  .WBdmem(WBdmem),
  .WBAlu(WBAlu),
  .WBPC(WBPC),
  .WBSel(Reg_WBSel),
  .forwardA(forwardA),

  //mmu
  .priv_o(priv),
  .csr_satp(csr_satp),
  .sstatus_sum(sstatus_sum),

  //UART CLINT
  .mtip(mtip),
  .msip(msip),
  .meip(meip)
  );
  
  hazard_unit HAZARD (
    .clk(clk),
    .rst(rst),
    .IDrs1(IDrs1), //Change
    .IDrs2(IDrs2), //Change
    .EXrd(EXrd),
    .EXmemRead(EXmemRead),
    .csr_branch_signal(EX_csr_branch_signal),
    .PCSel(PCSel),
    .jump_taken(jump_taken),

    .stall_IMEM(stall_IMEM),
    .stall_DMEM(stall_DMEM),
    .hazard_signal(hazard_signal),

    //except
    .pc_misaligned(pc_misaligned),
    .invalid_inst(invalid_inst),
    .instr_fault_mmu_DMEM(instr_fault_mmu_DMEM), 
    .load_fault_mmu_DMEM(load_fault_mmu_DMEM),
    .store_fault_mmu_DMEM(store_fault_mmu_DMEM),
    .instr_fault_mmu_IMEM(instr_fault_mmu_IMEM),
    .load_fault_mmu_IMEM(load_fault_mmu_IMEM),
    .store_fault_mmu_IMEM(store_fault_mmu_IMEM),
    .faulting_inst_i(faulting_inst_ID),
    .faulting_va_IMEM_i(faulting_va_IMEM_ID),

    .faulting_inst_o(faulting_inst),
    .faulting_va_IMEM_o(faulting_va_IMEM),
    .trapID(trapID)
  );
  
  ALU ALU (
    .clk(clk),
    .rdata1(EXrdata1),
    .rdata2(EXrdata2),
    .PC(EXPC),
    .imm(EXimm),
    .ASel(ALU_ASel),
    .BSel(ALU_BSel),
    .operation(ALU_Sel),
    .result(alu_out),
    .MEMAlu(MEMAlu),
    .WBdmem(WBdmem),
    .WBAlu(WBAlu),
    .WBPC(WBPC),
    .WBSel(Reg_WBSel),
    .forwardA(forwardA),
    .forwardB(forwardB),

    //csr forward
    .MEM_csr_reg_en(MEM_csr_reg_en),
    .WB_csr_reg_en(WB_csr_reg_en),
    .MEM_csr_rresult(MEM_csr_rresult),
    .WB_csr_rresult(WB_csr_rresult)
  );

  branch_comp COMP (
    .clk(clk),
    .sign_select(branch_signed),
    .rdata1(EXrdata1),
    .rdata2(EXrdata2),
    .equal(brEq),
    .less_than(brLt),
    .forwardBranchA(forwardBranchA),
    .forwardBranchB(forwardBranchB),
    .MEMAlu(MEMAlu),
    .WBdmem(WBdmem),
    .WBAlu(WBAlu),
    .WBPC(WBPC),
    .WBSel(Reg_WBSel),

    //csr forward
    .MEM_csr_reg_en(MEM_csr_reg_en),
    .WB_csr_reg_en(WB_csr_reg_en),
    .MEM_csr_rresult(MEM_csr_rresult),
    .WB_csr_rresult(WB_csr_rresult)
  );
endmodule