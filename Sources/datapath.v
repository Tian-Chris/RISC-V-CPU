`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/22/2025 09:48:02 AM
// Design Name: 
// Module Name: datapath
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


module datapath(
    input wire clk,
    input wire rst,
    input wire [31:0] instruct, //ID
    input wire brEq,
    input wire brLt,
    input wire [4:0] MEMrd,
    input wire [4:0] WBrd,
    input wire jump_taken,
    output wire jump_early,
    output wire branch_early,
    output wire [2:0] funct3,
    output reg PCSel,
    output wire Reg_WEn, 
    output wire [2:0] imm_gen_sel, // 0-5 = I-J
    output wire branch_signed,
    output wire ALU_BSel, //0 = rdata1, 1 = PC + 4
    output wire ALU_ASel, //0 = rdata2, 1 = imm
    output wire [3:0] ALU_Sel, //0-8 add-shift_right
    output wire dmemRW, //1 = write, 0 = read
    output wire [1:0] Reg_WBSel, // 0 = dmem, 1 = alu, 2 = PC+4
    output reg [1:0] forwardA,
    output reg [1:0] forwardB,
    output reg [1:0] forwardDmem,
    output reg [1:0] forwardBranchA,
    output reg [1:0] forwardBranchB,
    output wire IDmemRead,

    // load hazard detection
    output wire [1:0] Reg_WBSelID,
    output wire [1:0] Reg_WBSelEX,
    
    //flush
    input  wire [3:0] hazard_signal,
    
    //branch predict
    output reg branch_resolved,
    output reg actual_taken,
    output reg mispredict

    //debug
    `ifdef DEBUG
        , output wire Reg_WEnMEMo,
        output wire Reg_WEnWBo,
        output wire [4:0] rs1_EXo,
        output wire [4:0] rs2_EXo
    `endif
    );
    
    //ID Stage Signals
    wire        ID_is_jump;
    wire        ID_is_branch;
    wire [2:0]  ID_funct3;
    wire        ID_Reg_WEn; 
    wire [2:0]  ID_imm_gen_sel;  // 0-5 = I-J
    wire        ID_branch_signed;
    wire        ID_ALU_BSel;     //0 = rdata1, 1 = PC + 4
    wire        ID_ALU_ASel;     //0 = rdata2, 1 = imm
    wire [3:0]  ID_ALU_Sel;      //0-8 add-shift_right
    wire        ID_dmemRW;       //1 = write, 0 = read
    wire [1:0]  ID_Reg_WBSel;    // 0 = dmem, 1 = alu, 2 = PC+4
    wire [1:0]  ID_uses_reg;
    wire [4:0]  ID_rs1_raw;
    wire [4:0]  ID_rs2_raw;

    //EX Stage Signals
    reg        EX_is_jump;
    reg        EX_is_branch;
    reg [2:0]  EX_funct3;
    reg        EX_Reg_WEn; 
    reg        EX_dmemRW;    
    reg [1:0]  EX_Reg_WBSel;  
    reg        EX_branch_signed;
    reg        EX_ALU_BSel;  
    reg        EX_ALU_ASel;     
    reg [3:0]  EX_ALU_Sel;   
    reg [1:0]  EX_uses_reg;
    reg [4:0]  EX_rs1_raw;
    reg [4:0]  EX_rs2_raw;

    //MEM Stage Signals
    reg        MEM_is_jump;
    reg        MEM_is_branch;
    reg [2:0]  MEM_funct3;
    reg        MEM_Reg_WEn; 
    reg        MEM_branch_signed;
    reg        MEM_dmemRW;    
    reg [1:0]  MEM_Reg_WBSel;  
    reg        MEM_BrEq; //br inputs 1 stage delayed
    reg        MEM_BrLT;

    //WB Stage Signals
    reg        WB_Reg_WEn; 
    reg [1:0]  WB_Reg_WBSel; 

    datapath_decoder DEC (
        .instruct(instruct),
        .funct3(ID_funct3),
        .rs1_raw(ID_rs1_raw),
        .rs2_raw(ID_rs2_raw), 
        .imm_gen_sel(ID_imm_gen_sel),
        .is_jump(ID_is_jump),
        .uses_reg(ID_uses_reg),
        .is_branch(ID_is_branch), 
        .Reg_WEn(ID_Reg_WEn),
        .Reg_WBSel(ID_Reg_WBSel),
        .branch_signed(ID_branch_signed),
        .ALU_ASel(ID_ALU_ASel),
        .ALU_BSel(ID_ALU_BSel),
        .ALU_Sel(ID_ALU_Sel),
        .dmemRW(ID_dmemRW)
    );

    always @(posedge clk) begin
        if(rst || hazard_signal == `FLUSH_ALL) begin
            EX_is_jump        <= 0;
            EX_is_branch      <= 0;
            EX_funct3         <= 0;
            EX_Reg_WEn        <= 0; 
            EX_branch_signed  <= 0;
            EX_ALU_BSel       <= 0; 
            EX_ALU_ASel       <= 0; 
            EX_ALU_Sel        <= 0;    
            EX_dmemRW         <= 0;  
            EX_Reg_WBSel      <= 0; 
            EX_uses_reg       <= 0;
            EX_rs1_raw        <= 0;
            EX_rs2_raw        <= 0;

            MEM_is_jump       <= 0;
            MEM_is_branch     <= 0;
            MEM_funct3        <= 0;
            MEM_Reg_WEn       <= 0; 
            MEM_branch_signed <= 0;
            MEM_dmemRW        <= 0;
            MEM_Reg_WBSel     <= 0;
            MEM_BrEq          <= 0;
            MEM_BrLT          <= 0;

            if(rst) begin
                WB_Reg_WEn        <= 0;
                WB_Reg_WBSel      <= 0;
            end
        end
        else begin
            EX_is_jump        <= ID_is_jump;
            EX_is_branch      <= ID_is_branch;
            EX_funct3         <= ID_funct3;
            EX_Reg_WEn        <= ID_Reg_WEn; 
            EX_branch_signed  <= ID_branch_signed;
            EX_ALU_BSel       <= ID_ALU_BSel; 
            EX_ALU_ASel       <= ID_ALU_ASel; 
            EX_ALU_Sel        <= ID_ALU_Sel;    
            EX_dmemRW         <= ID_dmemRW;  
            EX_Reg_WBSel      <= ID_Reg_WBSel; 
            EX_uses_reg       <= ID_uses_reg;
            EX_rs1_raw        <= ID_rs1_raw;
            EX_rs2_raw        <= ID_rs2_raw;

            MEM_is_jump       <= EX_is_jump;
            MEM_is_branch     <= EX_is_branch;
            MEM_funct3        <= EX_funct3;
            MEM_Reg_WEn       <= EX_Reg_WEn; 
            MEM_branch_signed <= EX_branch_signed;
            MEM_dmemRW        <= EX_dmemRW;
            MEM_Reg_WBSel     <= EX_Reg_WBSel;
            MEM_BrEq          <= brEq;
            MEM_BrLT          <= brLt;

            WB_Reg_WEn        <= MEM_Reg_WEn;
            WB_Reg_WBSel      <= MEM_Reg_WBSel;
        end
        
        $display("=== Signal Values ===");
        $display("jump_early: %b, branch_early: %b, funct3: %b", jump_early, branch_early, funct3);
        $display("PCSel: %b, Reg_WEn: %b, imm_gen_sel: %b", PCSel, Reg_WEn, imm_gen_sel);
        $display("branch_signed: %b, ALU_BSel: %b, ALU_ASel: %b, ALU_Sel: %b", branch_signed, ALU_BSel, ALU_ASel, ALU_Sel);
        $display("dmemRW: %b, Reg_WBSel: %b, IDmemRead: %b", dmemRW, Reg_WBSel, IDmemRead);
        $display("Reg_WBSelID: %b, Reg_WBSelEX: %b", Reg_WBSelID, Reg_WBSelEX);
        $display("forwardA: %b, forwardB: %b, forwardDmem: %b", forwardA, forwardB, forwardDmem);
        $display("forwardBranchA: %b, forwardBranchB: %b", forwardBranchA, forwardBranchB);
        $display("hazard_signal: %b", hazard_signal);
        $display("branch_resolved: %b, actual_taken: %b, mispredict: %b", branch_resolved, actual_taken, mispredict);
    end

    // =============
    //    Outputs
    // =============
    assign jump_early    = ID_is_jump;
    assign branch_early  = ID_is_branch;
    assign imm_gen_sel   = ID_imm_gen_sel;
    assign Reg_WEn       = WB_Reg_WEn;
    assign Reg_WBSel     = WB_Reg_WBSel;
    assign Reg_WBSelID   = ID_Reg_WBSel;
    assign Reg_WBSelEX   = EX_Reg_WBSel;
    assign branch_signed = EX_branch_signed;
    assign ALU_BSel      = EX_ALU_BSel;
    assign ALU_ASel      = EX_ALU_ASel;
    assign ALU_Sel       = EX_ALU_Sel;
    assign funct3        = MEM_funct3;
    assign dmemRW        = MEM_dmemRW;
    assign IDmemRead     = (ID_Reg_WBSel == 2'b00); //for data hazard

    // =============
    //  Forwarding
    // =============
    wire [4:0] rs1_EX = EX_uses_reg[0] ? EX_rs1_raw : 5'd0;
    wire [4:0] rs2_EX = EX_uses_reg[1] ? EX_rs2_raw : 5'd0;
    always @(*) begin
        forwardA = 2'b00;
        forwardB = 2'b00;
        forwardDmem = 2'b00;
        forwardBranchA = 2'b00;
        forwardBranchB = 2'b00;

        if (MEM_is_branch) begin
            // Forward for branch comparison only
            if (MEM_Reg_WEn && MEMrd != 0 && MEMrd == rs1_EX)
                forwardBranchA = 2'b10;
            else if (WB_Reg_WEn && WBrd != 0 && WBrd == rs1_EX)
                forwardBranchA = 2'b01;
    
            if (MEM_Reg_WEn && MEMrd != 0 && MEMrd == rs2_EX)
                forwardBranchB = 2'b10;
            else if (WB_Reg_WEn && WBrd != 0 && WBrd == rs2_EX)
                forwardBranchB = 2'b01;
        end
        else begin
            // Normal ALU forwarding
            if (MEM_Reg_WEn && MEMrd != 0 && MEMrd == rs1_EX)
                forwardA = 2'b10;
            else if (WB_Reg_WEn && WBrd != 0 && WBrd == rs1_EX)
                forwardA = 2'b01;
    
            if (EX_dmemRW == 1) begin
                if (MEM_Reg_WEn && MEMrd != 0 && MEMrd == rs2_EX)
                    forwardDmem = 2'b10;
                else if (WB_Reg_WEn && WBrd != 0 && WBrd == rs2_EX)
                    forwardDmem = 2'b01;
            end
            else begin
                if (MEM_Reg_WEn && MEMrd != 0 && MEMrd == rs2_EX)
                    forwardB = 2'b10;
                else if (WB_Reg_WEn && WBrd != 0 && WBrd == rs2_EX)
                    forwardB = 2'b01;
            end
        end
    end

    always @(*) begin //for flush

        if (MEM_is_jump) begin
            if(jump_taken)
                PCSel = 0;
            else
                PCSel = 1; // JAL or JALR
            branch_resolved = 0;
            mispredict = 0;
        end 
        else if (MEM_is_branch) begin
            case (MEM_funct3)
                3'b000: PCSel = MEM_BrEq;
                3'b001: PCSel = !MEM_BrEq;
                3'b100: PCSel = MEM_BrLT;
                3'b110: PCSel = MEM_BrLT;
                3'b101: PCSel = !MEM_BrLT;
                3'b111: PCSel = !MEM_BrLT;
                default: PCSel = 0;
            endcase
            branch_resolved = 1;
            actual_taken = PCSel;
            if(jump_taken && PCSel) begin
                PCSel = 0;
                mispredict = 0;
            end
            else if(jump_taken && !PCSel) begin
                PCSel = 1;
                mispredict = 1;
            end
        end 
        else begin
            mispredict = 0;
            branch_resolved = 0;
            PCSel = 0;
            actual_taken = 0;
        end
    end

    //debug
    `ifdef DEBUG
        assign Reg_WEnMEMo = MEM_Reg_WEn;
        assign Reg_WEnWBo = WB_Reg_WEn;
        assign rs1_EXo = rs1_EX;
        assign rs2_EXo = rs2_EX;
    `endif
endmodule