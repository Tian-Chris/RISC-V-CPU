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
  input wire rst,
  output wire ecall
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
    wire [31:0] instruction;
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
    wire [4:0]  IFrs1 = rs1;
    wire [4:0]  IFrs2 = rs2;
    
    //mmu
    wire  [1:0]  priv;
    wire  [31:0] csr_satp;
    wire        sstatus_sum;
    wire        instr_fault_mmu_IMEM;
    wire        load_fault_mmu_IMEM;
    wire        store_fault_mmu_IMEM;
    wire [31:0] faulting_va_IMEM;
    wire        access_is_load_IMEM = 0;
    wire        access_is_store_IMEM = 0;
    wire        access_is_inst_IMEM = 1;
    wire [31:0] PPC;
    //mmudmem
    wire        instr_fault_mmu_DMEM;
    wire        load_fault_mmu_DMEM;
    wire        store_fault_mmu_DMEM;
    wire [31:0] faulting_va_DMEM;
    wire        access_is_inst_DMEM = 0;
    wire [31:0] PPC_DMEM;
    wire        instr_fault_mmu = instr_fault_mmu_DMEM | instr_fault_mmu_IMEM;
    wire        load_fault_mmu  = load_fault_mmu_DMEM  | load_fault_mmu_IMEM;
    wire        store_fault_mmu = store_fault_mmu_DMEM | store_fault_mmu_IMEM;
    wire [3:0] hazard_signal;
    
    //ID Stage Reg
    wire  [31:0] IDinstruct;
    wire  [31:0] IDPC;
    wire  [4:0]  IDrs1;
    wire  [4:0]  IDrs2;
    wire  [4:0]  IDrd;
    wire         IDmemRead;
    wire  [31:0] IDinstCSR;
    wire         access_is_load_ID;
    wire         access_is_store_ID;

    //exception
    wire  [4:0]  trapID;
    wire         pc_misaligned       = (pc[1:0] != 2'b00);
    wire         invalid_inst;  // the signal
    wire  [31:0] faulting_inst; // the inst

    assign trapID = pc_misaligned   ? `EXCEPT_MISALIGNED_PC    :
                    invalid_inst    ? `EXCEPT_ILLEGAL_INST     : 
                    instr_fault_mmu ? `EXCEPT_INST_PAGE_FAULT  : 
                    instr_fault_mmu ? `EXCEPT_LOAD_PAGE_FAULT  :
                    instr_fault_mmu ? `EXCEPT_STORE_PAGE_FAULT :`EXCEPT_DO_NOTHING;

    //interrupt
    wire mtip;
    wire msip;
    wire meip;

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
    reg  [31:0] EXinstruct;
    reg  [31:0] EXPC;
    reg  [31:0] EXrdata1;
    reg  [31:0] EXrdata2;
    reg  [31:0] EXimm;
    reg  [4:0]  EXrd;
    reg  [31:0] DMEMPreClockData;
    reg  [31:0] wdata;
    reg         EXjump_taken;
    reg  [2:0]  pht_indexEX;
    reg  [31:0] PC_savedEX;
    reg  [31:0] EXinstCSR;
    wire        EX_csr_reg_en;
    wire        EX_csr_branch_signal;
    wire [31:0] EX_csr_branch_address;
    reg         access_is_load_EX;
    reg         access_is_store_EX;
    
    //MEM Stage Reg
    reg  [31:0] MEMinstruct;
    reg  [31:0] MEMAlu;
    reg  [31:0] MEMrdata2;
    reg  [31:0] MEMPC;
    reg  [4:0]  MEMrd;        
    reg         MEMjump_taken;
    reg  [2:0]  pht_indexMEM;
    reg  [31:0] PC_savedMEM;
    wire [31:0] MEM_csr_rresult; //result of read
    reg         MEM_csr_reg_en;
    wire [31:0] MEM_csr_data_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    wire [31:0] MEM_csr_addr_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    reg         access_is_load_MEM;
    reg         access_is_store_MEM;
    wire [31:0] dmem_out;
    
    //WB Stage Reg
    reg  [31:0] WBinstruct;
    reg  [31:0] WBAlu;
    reg  [31:0] WBPC;
    reg  [31:0] WBdmem;
    reg  [4:0]  WBrd;
    reg         WB_csr_reg_en;
    wire        WB_csr_wben;
    wire [11:0] WB_csr_wbaddr;   //address written
    wire [31:0] WB_csr_wbdata;   //data written
    reg  [31:0] WB_csr_rresult; //result of read
    reg  [31:0] WB_csr_data_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    reg  [31:0] WB_csr_addr_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    
    //debug
    `ifdef DEBUG
      assign pco          = pc;
      assign instructiono = instruction; 
      assign alu_outo     = alu_out;
      assign immo         = imm;
      assign rdata1o      = rdata1;
      assign rdata2o      = rdata2;
      assign privo        = priv;
    `endif 

    // ID-EX
    always @(posedge clk) begin
        if(rst) begin
            EXinstruct   <= `INST_NOP;
            EXPC         <= 32'h00000000;
            EXrdata1     <= 32'h00000000;
            EXrdata2     <= 32'h00000000;
            EXimm        <= 32'h00000000;
            EXrd         <= 5'b0;
            EXjump_taken <= 0;
            pht_indexEX  <= 0;
            PC_savedEX   <= 32'h00000000;
            EXinstCSR    <= `INST_NOP;
            access_is_load_EX <= 0;
            access_is_store_EX <= 0;
        end
        else begin
            EXinstruct   <= IDinstruct;
            EXPC         <= IDPC;
            EXrdata1     <= rdata1;
            EXrdata2     <= rdata2;
            EXimm        <= imm;
            EXrd         <= IDrd;
            EXjump_taken <= jump_taken;
            pht_indexEX  <= pht_index;
            PC_savedEX   <= PC_saved;
            EXinstCSR    <= IDinstCSR;
            access_is_load_EX <= access_is_load_ID;
            access_is_store_EX <= access_is_store_ID;
        end
    end
        
    //forwarding into dmem
    always @(*) begin
        wdata = (Reg_WBSel == 2'b00) ? WBdmem : 
                (Reg_WBSel == 2'b01) ? WBAlu : WBPC + 4;
        DMEMPreClockData = forwardDmem[1] ? MEMAlu : (forwardDmem[0] ? wdata : EXrdata2);
    end

    // EX-MEM
    always @(posedge clk) begin
        if(rst) begin
            MEMinstruct    <= `INST_NOP;
            MEMPC          <= 32'h00000000;
            MEMrdata2      <= 32'h00000000;
            MEMAlu         <= 32'h00000000;
            MEMrd          <= 5'h00;
            MEMjump_taken  <= 1'b0;
            pht_indexMEM   <= 3'h0;
            PC_savedMEM    <= 32'h00000000;
            MEM_csr_reg_en <= 1'b0;
            access_is_load_MEM <= 1'b0;
            access_is_store_MEM <= 1'b0;
        end
        else begin
            MEMinstruct    <= EXinstruct;
            MEMPC          <= EXPC;
            MEMrdata2      <= DMEMPreClockData;
            MEMAlu         <= alu_out;
            MEMrd          <= EXrd;
            MEMjump_taken  <= EXjump_taken;
            pht_indexMEM   <= pht_indexEX;
            PC_savedMEM    <= PC_savedEX;
            MEM_csr_reg_en <= EX_csr_reg_en;
            access_is_load_MEM <= access_is_load_EX;
            access_is_store_MEM <= access_is_store_EX;
        end
    end
        
    //MEM-WB
    always @(posedge clk) begin
        if(rst) begin
            WBPC              <= 32'h00000000;
            WBdmem            <= 32'h00000000;
            WBAlu             <= 32'h00000000;
            WBinstruct        <= `INST_NOP;
            WBrd              <= 5'h0;
            WB_csr_rresult    <= 32'h00000000; //result of read
            WB_csr_reg_en     <= 1'h0;
            WB_csr_data_to_wb <= 32'h00000000;  //csr_data_to_wb -> WB -> csr_wdata 
            WB_csr_addr_to_wb <= 32'h00000000;  //csr_data_to_wb -> WB -> csr_wdata 
        end
        else begin
            WBPC              <= MEMPC;
            WBdmem            <= dmem_out;
            WBAlu             <= MEMAlu;
            WBinstruct        <= MEMinstruct;
            WBrd              <= MEMrd;
            WB_csr_rresult    <= MEM_csr_rresult; //result of read
            WB_csr_reg_en     <= MEM_csr_reg_en;
            WB_csr_data_to_wb <= MEM_csr_data_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
            WB_csr_addr_to_wb <= MEM_csr_addr_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
        end
    end
    
    //Flush
    always @(posedge clk) begin
        if (hazard_signal == `FLUSH_ALL) begin          
            EXinstruct  <= `INST_NOP;
            EXrd        <= 5'b0;           
            MEMinstruct <= `INST_NOP;
            MEMrd       <= 5'b0;             
        end
    end

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

  // Instruction Memory
  imem IMEM (
    //IMEM
    .rst(rst),
    .inst(instruction),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .hazard_signal(hazard_signal),
    
    //DMEM
    .clk(clk),
    .RW(dmemRW),
    .funct3(funct3),
    .wdata(MEMrdata2),
    .rdata(dmem_out),

    //MMU
    .priv(priv),
    .csr_satp(csr_satp),
    .sstatus_sum(sstatus_sum), 

    //CLINT AND UART
    .mtip(mtip),
    .msip(msip),
    .meip(meip),

    //IMEM
    .VPC_IMEM(pc), 
    .access_is_load_IMEM(access_is_load_IMEM),
    .access_is_store_IMEM(access_is_store_IMEM),
    .access_is_inst_IMEM(access_is_inst_IMEM),
    .instr_fault_mmu_IMEM(instr_fault_mmu_IMEM),
    .load_fault_mmu_IMEM(load_fault_mmu_IMEM),
    .store_fault_mmu_IMEM(store_fault_mmu_IMEM),
    .faulting_va_IMEM(faulting_va_IMEM),

    //DMEM
    .VPC_DMEM(MEMAlu), 
    .access_is_load_DMEM(access_is_load_MEM),
    .access_is_store_DMEM(access_is_store_MEM),
    .access_is_inst_DMEM(access_is_inst_DMEM),
    .instr_fault_mmu_DMEM(instr_fault_mmu_DMEM),
    .load_fault_mmu_DMEM(load_fault_mmu_DMEM),
    .store_fault_mmu_DMEM(store_fault_mmu_DMEM),
    .faulting_va_DMEM(faulting_va_DMEM)
    );
 
  // Decoder /IF-ID PIPE
  decoder DECODER(
    .clk(clk),
    .rst(rst),
    .hazard_signal(hazard_signal),
    .instruction(instruction),
    .pc(pc),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .csr_branch_signal(EX_csr_branch_signal),
    .IDinstruct_o(IDinstruct),
    .IDPC_o(IDPC),
    .IDrs1_o(IDrs1),
    .IDrs2_o(IDrs2),
    .IDrd_o(IDrd),
    .IDinstCSR_o(IDinstCSR),
    .invalid_inst(invalid_inst),
    .fence_active(fence),
    .faulting_inst(faulting_inst),
    .access_is_load_ID(access_is_load_ID),
    .access_is_store_ID(access_is_store_ID),
    .ecall(ecall)
  );

  imm_gen IMM (
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
    .IDmemRead(IDmemRead),
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
  
  //trap
  .csr_trapID(trapID),
  .csr_trapPC(pc),
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
  .priv(priv),
  .csr_satp(csr_satp),
  .sstatus_sum(sstatus_sum),

  //UART CLINT
  .mtip(mtip),
  .msip(msip),
  .meip(meip)
  );
  
  hazard_unit HAZARD (
    .IFrs1(IFrs1),
    .IFrs2(IFrs2),
    .IDrd(IDrd),
    .IDmemRead(IDmemRead),

    .PCSel(PCSel),
    .jump_taken(jump_taken),

    .stall_IMEM(stall_IMEM),
    .stall_DMEM(stall_DMEM),
    .hazard_signal(hazard_signal)
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
    .forwardB(forwardB)
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