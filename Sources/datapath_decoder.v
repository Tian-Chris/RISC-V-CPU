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
// Dependelse ifencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module datapath_decoder(
    input wire [31:0] instruct,
    output reg        jump_early,
    output reg        is_jump,
    output reg        is_branch,    //branch earlyresolved
    output reg [2:0]  funct3,
    output reg        Reg_WEn, 
    output reg [2:0]  imm_gen_sel,  // 0-5 = I-J
    output reg        branch_signed,
    output reg        ALU_BSel,     //0 = rdata1, 1 = PC + 4
    output reg        ALU_ASel,     //0 = rdata2, 1 = imm
    output reg [3:0]  ALU_Sel,      //0-8 add-shift_right
    output reg        dmemRW,       //1 = write, 0 = read
    output reg [1:0]  Reg_WBSel,    // 0 = dmem, 1 = alu, 2 = PC+4
    output reg [1:0]  uses_reg,
    output reg [4:0]  rs1_raw,
    output reg [4:0]  rs2_raw
    );
    `include "inst_defs.v"

    always @(*) begin
        funct3          = instruct[14:12];
        rs1_raw         = instruct[19:15];
        rs2_raw         = instruct[24:20];
        imm_gen_sel     = 3'b000;
        jump_early      = 1'b0;
        is_jump         = 1'b0;
        uses_reg        = 2'b00;  //for forwarding
        is_branch       = 1'b0;   //branchresolved/branchearly
        Reg_WEn         = 1'b0;
        Reg_WBSel       = 2'b11;  // 00-WBdmem, 01-WBAlu, 10-WBPC + 4, 11-Do Nothing
        branch_signed   = 1'b0;
        ALU_ASel        = 1'b0;
        ALU_BSel        = 1'b0;
        ALU_Sel         = 4'b0000;
        dmemRW          = 1'b0;   //AKA is store

        // ==========
        //   R-type
        // ==========
        if (instruct  == `INST_NOP)   begin
        end
        else if ((instruct & `INST_ADD_MASK)   == `INST_ADD)   begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
        end
        else if ((instruct & `INST_SUB_MASK)   == `INST_SUB)   begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b0001;
        end
        else if ((instruct & `INST_AND_MASK)   == `INST_AND)   begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b0010;
        end
        else if ((instruct & `INST_OR_MASK)    == `INST_OR)    begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b0011;
        end
        else if ((instruct & `INST_XOR_MASK)   == `INST_XOR)   begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b0100;
        end
        else if ((instruct & `INST_SLL_MASK)   == `INST_SLL)   begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b0101;
        end
        else if ((instruct & `INST_SRL_MASK)   == `INST_SRL)   begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b0110;
        end
        else if ((instruct & `INST_SRA_MASK)   == `INST_SRA)   begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b0111;
        end
        else if ((instruct & `INST_SLT_MASK)   == `INST_SLT)   begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b1001;
        end
        else if ((instruct & `INST_SLTU_MASK)  == `INST_SLTU)  begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b1000;
        end

        // ==========
        //   I-type
        // ==========
        else if ((instruct & `INST_ANDI_MASK)  == `INST_ANDI)  begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b0010;
        end
        else if ((instruct & `INST_ADDI_MASK)  == `INST_ADDI)  begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b0000;
        end
        else if ((instruct & `INST_SLTI_MASK)  == `INST_SLTI)  begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b1001;
        end
        else if ((instruct & `INST_SLTIU_MASK) == `INST_SLTIU) begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b1000;
        end
        else if ((instruct & `INST_ORI_MASK)   == `INST_ORI)   begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b0011;
        end
        else if ((instruct & `INST_XORI_MASK)  == `INST_XORI)  begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b0100;
        end
        else if ((instruct & `INST_SLLI_MASK)  == `INST_SLLI)  begin
            imm_gen_sel = 3'b001;
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b0101;
        end
        else if ((instruct & `INST_SRLI_MASK)  == `INST_SRLI)  begin
            imm_gen_sel = 3'b001;            
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b0110;
        end
        else if ((instruct & `INST_SRAI_MASK)  == `INST_SRAI)  begin
            imm_gen_sel = 3'b001;
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b0111;
        end

        // ==========
        //   Load
        // ==========
        else if ((instruct & `INST_LB_MASK)    == `INST_LB)    begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b00;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_LBU_MASK)   == `INST_LBU)   begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b00;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_LH_MASK)    == `INST_LH)    begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b00;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_LHU_MASK)   == `INST_LHU)   begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b00;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_LW_MASK)    == `INST_LW)    begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b00;
            ALU_BSel    = 1'b1;
        end

        // ==========
        //   Store
        // ==========
        else if ((instruct & `INST_SB_MASK)    == `INST_SB)    begin
            imm_gen_sel = 3'b010;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            ALU_BSel    = 1'b1;
            dmemRW      = 1'b1;
        end
        else if ((instruct & `INST_SH_MASK)    == `INST_SH)    begin
            imm_gen_sel = 3'b010;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            ALU_BSel    = 1'b1;
            dmemRW      = 1'b1;
        end
        else if ((instruct & `INST_SW_MASK)    == `INST_SW)    begin
            imm_gen_sel = 3'b010;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            ALU_BSel    = 1'b1;
            dmemRW      = 1'b1;
        end

        // ==========
        //   Branch
        // ==========
        else if ((instruct & `INST_BEQ_MASK)   == `INST_BEQ)   begin
            is_branch   = 1;
            imm_gen_sel = 3'b011;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_BNE_MASK)   == `INST_BNE)   begin
            is_branch   = 1;
            imm_gen_sel = 3'b011;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_BLT_MASK)   == `INST_BLT)   begin
            is_branch   = 1;
            imm_gen_sel = 3'b011;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_BGE_MASK)   == `INST_BGE)   begin
            is_branch   = 1;
            imm_gen_sel = 3'b011;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_BLTU_MASK)  == `INST_BLTU)  begin
            is_branch   = 1;
            imm_gen_sel = 3'b011;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            branch_signed = 1'b1; //??????????????????????
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_BGEU_MASK)  == `INST_BGEU)  begin
            is_branch   = 1;
            imm_gen_sel = 3'b011;
            uses_reg    = 2'b11;
            Reg_WBSel   = 2'b00;
            branch_signed = 1'b1;
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
        end

        // ==========
        //   Jump
        // ==========
        else if ((instruct & `INST_JAL_MASK)   == `INST_JAL)   begin
            jump_early  = 1;
            is_jump     = 1;
            imm_gen_sel = 3'b101;
            uses_reg    = 2'b00;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b11;
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
        end
        else if ((instruct & `INST_JALR_MASK)  == `INST_JALR)  begin
            is_jump  = 1;
            imm_gen_sel = 3'b000;
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b11;
            ALU_BSel    = 1'b1;
        end

        // ==========
        //   Other
        // ==========
        else if ((instruct & `INST_LUI_MASK)   == `INST_LUI)   begin
            imm_gen_sel = 3'b100;
            uses_reg    = 2'b00;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            branch_signed = 1'b1;
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
            ALU_Sel     = 4'b1011;
        end
        else if ((instruct & `INST_AUIPC_MASK) == `INST_AUIPC) begin
            imm_gen_sel = 3'b100;
            uses_reg    = 2'b00;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_ASel    = 1'b1;
            ALU_BSel    = 1'b1;
        end

        else if ((instruct & `CSR_INST_MASK)   == `CSRRW_INST) begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
        end
        else if ((instruct & `CSR_INST_MASK)   == `CSRRS_INST) begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
        end
        else if ((instruct & `CSR_INST_MASK)   == `CSRRC_INST) begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
        end
        else if ((instruct & `CSR_INST_MASK)   == `CSRRWI_INST)begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
        end
        else if ((instruct & `CSR_INST_MASK)   == `CSRRSI_INST)begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
        end
        else if ((instruct & `CSR_INST_MASK)   == `CSRRCI_INST)begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
        end
        else if ((instruct & `CSR_INST_MASK)   == `MRET_INST)  begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b0;
        end
        else if ((instruct & `CSR_INST_MASK)   == `ECALL_INST) begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b0;
        end

        //M Extension
        else if ((instruct & `INST_MUL_MASK)   == `INST_MUL) begin
            uses_reg    = 2'b11;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b01;
            ALU_Sel     = 4'b1100;
        end

        else if((instruct & `INST_AMOSWAP_W_MASK)   == `INST_AMOSWAP_W) begin
            uses_reg    = 2'b01;
            Reg_WEn     = 1'b1;
            Reg_WBSel   = 2'b00;
            ALU_Sel     = 4'b1010;
        end
    end
endmodule