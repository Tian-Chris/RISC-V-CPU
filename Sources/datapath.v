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
    );
    `ifdef DEBUG_ALL
        `define DEBUG_DATAPATH
    `endif
    
    //ID Stage Signals
    wire        ID_jump_early;
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
    wire        EX_is_jump;
    wire        EX_is_branch;
    wire [2:0]  EX_funct3;
    wire        EX_Reg_WEn; 
    wire        EX_dmemRW;    
    wire [1:0]  EX_Reg_WBSel;  
    wire        EX_branch_signed;
    wire        EX_ALU_BSel;  
    wire        EX_ALU_ASel;     
    wire [3:0]  EX_ALU_Sel;   
    wire [1:0]  EX_uses_reg;
    wire [4:0]  EX_rs1_raw;
    wire [4:0]  EX_rs2_raw;

    //MEM Stage Signals
    wire        MEM_is_jump;
    wire        MEM_is_branch;
    wire [2:0]  MEM_funct3;
    wire        MEM_Reg_WEn; 
    wire        MEM_branch_signed;
    wire        MEM_dmemRW;    
    wire [1:0]  MEM_Reg_WBSel;  
    wire        MEM_BrEq; //br inputs 1 stage delayed
    wire        MEM_BrLT;

    //WB Stage Signals
    wire        WB_Reg_WEn; 
    wire [1:0]  WB_Reg_WBSel; 

    datapath_decoder DEC (
        .instruct(instruct),
        .funct3(ID_funct3),
        .rs1_raw(ID_rs1_raw),
        .rs2_raw(ID_rs2_raw), 
        .imm_gen_sel(ID_imm_gen_sel),
        .jump_early(ID_jump_early),
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

    // ============
    //   ID - EX
    // ============
    localparam EX_WIDTH = 1 + 1 + 3 + 1 + 1 + 2 + 1 + 1 + 1 + 4 + 2 + 5 + 5;
    wire [EX_WIDTH-1:0]  EX = {ID_is_jump, ID_is_branch, ID_funct3, ID_Reg_WEn, ID_branch_signed, ID_ALU_BSel, ID_ALU_ASel, 
                               ID_ALU_Sel, ID_dmemRW, ID_Reg_WBSel, ID_uses_reg, ID_rs1_raw, ID_rs2_raw};
    wire [EX_WIDTH-1:0]  EX_OUT;
    Pipe #(.STAGE(`STAGE_EX), .WIDTH(EX_WIDTH)) PIPE_EX (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(EX), .out_data(EX_OUT)
        );
    assign {EX_is_jump, EX_is_branch, EX_funct3, EX_Reg_WEn, EX_branch_signed, EX_ALU_BSel, EX_ALU_ASel, 
            EX_ALU_Sel, EX_dmemRW, EX_Reg_WBSel, EX_uses_reg, EX_rs1_raw, EX_rs2_raw} = EX_OUT; 
    
    // ============
    //   EX - MEM
    // ============
    localparam MEM_WIDTH = 1 + 1 + 3 + 1 + 1 + 1 + 2 + 1 + 1;
    wire [MEM_WIDTH-1:0]  MEM = {EX_is_jump, EX_is_branch, EX_funct3, EX_Reg_WEn, EX_branch_signed, EX_dmemRW, EX_Reg_WBSel, brEq, brLt};
    wire [MEM_WIDTH-1:0]  MEM_OUT;
    Pipe #(.STAGE(`STAGE_MEM), .WIDTH(MEM_WIDTH)) PIPE_MEM (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(MEM), .out_data(MEM_OUT)
        );
    assign {MEM_is_jump, MEM_is_branch, MEM_funct3, MEM_Reg_WEn, MEM_branch_signed, MEM_dmemRW, MEM_Reg_WBSel, MEM_brEq, MEM_brLt} = MEM_OUT; 
    
    // ============
    //   MEM - WB
    // ============
    localparam WB_WIDTH = 1 + 2;
    wire [WB_WIDTH-1:0]  WB = {MEM_Reg_WEn, MEM_Reg_WBSel};
    wire [WB_WIDTH-1:0]  WB_OUT;
    Pipe #(.STAGE(`STAGE_MEM), .WIDTH(WB_WIDTH)) PIPE_WB (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(WB), .out_data(WB_OUT)
        );
    assign {WB_Reg_WEn, WB_Reg_WBSel} = WB_OUT; 
    
    always @(posedge clk) begin
        `ifdef DEBUG_DATAPATH
            $display("===========  DATAPATH  ===========");
            $display("instruct: %h", instruct);
            $display("ID_jump_early: %b, branch_early: %b, ID_funct3: %b", ID_jump_early, branch_early, ID_funct3);
            $display("PCSel: %b, ID_Reg_WEn: %b, ID_imm_gen_sel: %b", PCSel, ID_Reg_WEn, ID_imm_gen_sel);
            $display("ID_Reg_WBSel: %b, EX_Reg_WBSel: %b, MEM_Reg_WBSel: %b, WB_Reg_WBSel: %b", ID_Reg_WBSel, EX_Reg_WBSel, MEM_Reg_WBSel, WB_Reg_WBSel);
            $display("ID_branch_signed: %b, ID_ALU_BSel: %b, ID_ALU_ASel: %b, ID_ALU_Sel: %b", ID_branch_signed, ID_ALU_BSel, ID_ALU_ASel, ID_ALU_Sel);
            $display("ID_dmemRW: %b, ID_Reg_WBSel: %b", ID_dmemRW, ID_Reg_WBSel);
            $display("Reg_WBSelID: %b, Reg_WBSelEX: %b", Reg_WBSelID, Reg_WBSelEX);
            $display("forwardA: %b, forwardB: %b, forwardDmem: %b", forwardA, forwardB, forwardDmem);
            $display("forwardBranchA: %b, forwardBranchB: %b", forwardBranchA, forwardBranchB);
            $display("hazard_signal: %b", hazard_signal);
            $display("branch_resolved: %b, actual_taken: %b, mispredict: %b", branch_resolved, actual_taken, mispredict);
            $display("FORWARD DEBUG | rs1_EX=%d rs2_EX=%d | MEMrd=%d | WBrd=%d | MEM_is_branch=%b | forwardA=%b | forwardBranchA=%b", 
             rs1_EX, rs2_EX, MEMrd, WBrd, MEM_is_branch, forwardA, forwardBranchA);
        `endif
    end

    // =============
    //    Outputs
    // =============
    assign jump_early    = ID_jump_early;
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

        if (EX_is_branch) begin
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
endmodule