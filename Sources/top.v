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
  input wire rst
  // Debug outputs
  `ifdef DEBUG
    , output wire [31:0] pco, instructiono, alu_outo, immo, rdata1o, rdata2o, MEMrdata2O, 
                       dmempreo, dmem_out, forwardAo, forwardBo, MEMAluo, wdatao, Out0, 
                       Out1, Out2, Out3, Out4, Out5, Out6, Out7, Out8, Out9, Out10, Out11, 
                       Out12, Out13, Out14, Out15, Out16, Out17, Out18, Out19, Out20, Out21, 
                       Out22, Out23, Out24, Out25, Out26, Out27, Out28, Out29, Out30, Out31,
    output wire [4:0]  rs1_EXo, rs2_EXo, MEMrdo, WBrdo,
    output wire [2:0]  phto,
    output wire [1:0]  Reg_WBSelIDo, Reg_WBSelEXo, flushOuto,
    output wire brEqo, brLto, Reg_WEno, PCSelo, stallo, Reg_WEnMEMo, Reg_WEnWBo
  `endif
   );
   
   `include "csr_defs.v"
    
    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] alu_out;
    wire [31:0] imm;
    wire [31:0] rdata1;
    wire [31:0] rdata2;
    wire brEq;
    wire brLt;
    wire Reg_WEn;
    wire PCSel;
    wire stall;
    wire [1:0] Reg_WBSelID;
    wire [1:0] Reg_WBSelEX;
    wire [4:0] rs1, rs2, rd;
    wire branch_signed, ALU_BSel, ALU_ASel, dmemRW;
    wire [2:0] funct3, imm_gen_sel;
    wire [3:0] ALU_Sel;
    wire [1:0] Reg_WBSel, forwardA, forwardB, forwardDmem, forwardBranchA, forwardBranchB;
    wire [4:0] IFrs1 = rs1;
    wire [4:0] IFrs2 = rs2;
    
    //ID Stage Reg
    reg [31:0] IDinstruct;
    reg [31:0] IDPC;
    reg [4:0]  IDrs1;
    reg [4:0]  IDrs2;
    reg [4:0]  IDrd;
    wire       IDmemRead;
    reg [31:0] IDinstCSR;
    wire pc_misaligned       = (pc[1:0] != 2'b00);
    reg [5:0]  trapID;
    always @(*) begin
        trapID = 6'h00;
        if (pc_misaligned) begin
            trapID         = `EXCEPT_MISALIGNED_PC;
        end
    end
    
    //early jump/branch
    wire jump_early;
    wire branch_early;
    wire [1:0] flush;
    wire [31:0] PC_Jump;
    wire jump_taken;
    //branch
    wire        branch_resolved;
    wire        actual_taken;
    wire [2:0]  pht_index;
    wire mispredict;
    wire [31:0] PC_saved;
    wire [1:0] flushOut;

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
    
    //MEM Stage Reg
    reg [31:0] MEMinstruct;
    reg [31:0] MEMAlu;
    reg [31:0] MEMrdata2;
    reg [31:0] MEMPC;
    reg [4:0]  MEMrd;        
    reg        MEMjump_taken;
    reg [2:0]  pht_indexMEM;
    reg [31:0] PC_savedMEM;
    wire [31:0] MEM_csr_rresult; //result of read
    reg        MEM_csr_reg_en;
    wire [31:0] MEM_csr_data_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    wire [31:0] MEM_csr_addr_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    
    //WB Stage Reg
    reg [31:0] WBinstruct;
    reg [31:0] WBAlu;
    reg [31:0] WBPC;
    reg [31:0] WBdmem;
    reg [4:0]  WBrd;
    reg        WB_csr_reg_en;
    wire        WB_csr_wben;
    wire [11:0] WB_csr_wbaddr;   //address written
    wire [31:0] WB_csr_wbdata;   //data written
    reg [31:0] WB_csr_rresult; //result of read
    reg [31:0] WB_csr_data_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    reg [31:0] WB_csr_addr_to_wb;  //csr_data_to_wb -> WB -> csr_wdata 
    
    //debug
    `ifdef DEBUG
      assign pco = pc;
      assign instructiono = instruction; 
      assign alu_outo = alu_out;
      assign immo = imm;
      assign rdata1o = rdata1;
      assign rdata2o = rdata2;
      assign brEqo = brEq;
      assign brLto = brLt;
      assign Reg_WEno = Reg_WEn;
      assign PCSelo = PCSel;
      assign stallo = stall;
      assign Reg_WBSelIDo = Reg_WBSelID;
      assign Reg_WBSelEXo = Reg_WBSelEX;
      assign dmempreo = DMEMPreClockData;
      assign forwardAo = jump_taken;
      assign forwardBo = flushOut[0];
      assign phto = pht_indexMEM;
      assign MEMAluo = MEMAlu;
      assign wdatao = wdata;
      assign MEMrdo = MEMrd;
      assign WBrdo = WBrd;
      assign MEMrdata2O = MEMrdata2;
      assign flushOuto = flushOut;
    `endif 

    
    // IF-ID
    always @(posedge clk) begin
         `ifdef DEBUG
            $display(" ");
            $display("PC: %h", pc);
        `endif
        if (!(stall)) begin
            if(instruction[6:0] == 7'b1110011) begin
                IDinstruct <= instruction;
                IDPC       <= pc;
                IDrs1      <= rs1;              // Don't read any reg
                IDrs2      <= 5'b0;
                IDrd       <= rd;              // Don't write any reg
                IDinstCSR  <= instruction;
            end
            else begin
                IDinstruct <= instruction;
                IDPC       <= pc;
                IDrs1      <= rs1;
                IDrs2      <= rs2;
                IDrd       <= rd;
                IDinstCSR  <= 32'b0;
            end
        end 
        else begin
            IDinstruct <= 32'h00000013; // NOP
            IDrs1 <= 5'b0;              // Don't read any reg
            IDrs2 <= 5'b0;
            IDrd  <= 5'b0;              // Don't write any reg
        end
    end

    // ID-EX
    always @(posedge clk) begin
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
    end
        
    //forwarding into dmem
    always @(*) begin
        wdata = (Reg_WBSel == 2'b00) ? WBdmem : 
                (Reg_WBSel == 2'b01) ? WBAlu : WBPC + 4;
        DMEMPreClockData = forwardDmem[1] ? MEMAlu : (forwardDmem[0] ? wdata : EXrdata2);
    end

    // EX-MEM
    always @(posedge clk) begin
        MEMinstruct <= EXinstruct;
        MEMPC <= EXPC;
        MEMrdata2 <= DMEMPreClockData;
        MEMAlu <= alu_out;
        MEMrd <= EXrd;
        MEMjump_taken <= EXjump_taken;
        pht_indexMEM <= pht_indexEX;
        PC_savedMEM <= PC_savedEX;
        MEM_csr_reg_en <= EX_csr_reg_en;
    end
        
    //MEM-WB
    always @(posedge clk) begin
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
    
    //Flush
    always @(posedge clk) begin
        if (flushOut == 2'b11) begin
            IDinstruct <= 32'h00000013; // NOP
            IDrs1 <= 5'b0;              // Don't read any reg
            IDrs2 <= 5'b0;
            IDrd  <= 5'b0;              // Don't write any reg
            EXinstruct <= 32'h00000013; // NOP
            EXrd  <= 5'b0;              // Don't write any reg
            MEMinstruct <= 32'h00000013; // NOP
            MEMrd  <= 5'b0;              // Don't write any reg
        end
        else if (flushOut == 2'b01)
        begin
            IDinstruct <= 32'h00000013; // NOP
            IDrs1 <= 5'b0;              // Don't read any reg
            IDrs2 <= 5'b0;
            IDrd  <= 5'b0;              // Don't write any reg
        end
    end
  // Program Counter
  PC PC (
    .clk(clk),
    .PC_ALU_input(MEMAlu),
    .PC_select(PCSel),
    .PC_Jump(PC_Jump),
    .jump_taken(jump_taken),
    .PC(pc),
    .PC_savedMEM(PC_savedMEM),
    .mispredict(mispredict),
    .stall(stall),
    .EX_csr_branch_signal(EX_csr_branch_signal),
    .EX_csr_branch_address(EX_csr_branch_address)
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
    .imm_in(IDinstruct),
    .imm_sel(imm_gen_sel),
    .imm_out(imm)
  );
  
  //early jump/branch predictor handler
  jump_branch_unit BP (
    .clk(clk),
    .jump_early(jump_early),
    .branch_early(branch_early),
    .immID(imm),
    .pc(IDPC),
    .branch_resolved(branch_resolved),
    .actual_taken(actual_taken),
    .pht_index(pht_index),
    .pht_indexMEM(pht_indexMEM),
    .PC_Jump(PC_Jump),
    .flush(flush),
    .jump_taken(jump_taken),
    .PC_saved(PC_saved)
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
    .flushIn(flush),
    .flushOut(flushOut),
    .IDmemRead(IDmemRead),
    .branch_resolved(branch_resolved),
    .actual_taken(actual_taken)
    
    `ifdef DEBUG
      , .Reg_WEnMEMo(Reg_WEnMEMo),
      .Reg_WEnWBo(Reg_WEnWBo),
      .rs1_EXo(rs1_EXo),
      .rs2_EXo(rs2_EXo)
    `endif
  );    

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

 
  //csr handler
  csr_handler CSR (
  .clk(clk),
  .rst(rst),
  .csr_trapID(trapID),
  .csr_trapPC(pc),
  .flush(flushOut),
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
  .forwardA(forwardA)
  );
  
  //hazard
  hazard_unit HAZARD (
    .IFrs1(IFrs1),
    .IFrs2(IFrs2),
    .IDrd(IDrd),
    .IDmemRead(IDmemRead),
    .stall(stall)
  );
  
  // ALU
  ALU ALU (
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

  // Branch Comparator
  branch_comp COMP (
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
    .WBSel(Reg_WBSel)
  );
  
  // Data Memory
  dmem DMEM (
    .clk(clk),
    .RW(dmemRW),
    .funct3(funct3),
    .address(MEMAlu),
    .wdata(MEMrdata2),
    .rdata(dmem_out)
  );
endmodule