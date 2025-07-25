`timescale 1ns / 1ps

module decoder (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  hazard_signal,
    input  wire [31:0] instruction,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    output wire [31:0] IDinstruct,
    output wire [4:0]  IDrs1,
    output wire [4:0]  IDrs2,
    output wire [4:0]  IDrd,
    output wire [31:0] IDinstCSR,
    output wire        invalid_inst,
    output wire        fence_active,
    output wire        access_is_load_ID,
    output wire        access_is_store_ID,
    output wire [31:0] faulting_inst,
    output wire        swap,
    output wire        ecall
);
    `include "inst_defs.v"
    `include "csr_defs.v"
    `ifdef DEBUG_ALL
        `define DEBUG_DECODER
    `endif
    
    assign IDinstruct = instruction;
    assign IDrs1      = rs1;              
    assign IDrs2      = (instruction[6:0] == 7'b1110011) ? 5'b0        : rs2;
    assign IDrd       = rd;              
    assign IDinstCSR  = (instruction[6:0] == 7'b1110011) ? instruction : 32'b0;

    reg [3:0] fence_stall_counter;
    reg fence_stall_active;
    assign fence_active = fence_stall_active || fence;
    always @(posedge clk or posedge rst) begin
        if (rst || hazard_signal == `FLUSH_EARLY || hazard_signal == `FLUSH_ALL ) begin
            fence_stall_counter <= 0;
            fence_stall_active <= 0;
        end 
        else if(hazard_signal != `STALL_MMU) begin
            if (fence && !fence_stall_active) begin
                fence_stall_active <= 1;
                fence_stall_counter <= 8;  // Stall for 8 cycles
            end else if (fence_stall_active) begin
                if (fence_stall_counter > 1)
                    fence_stall_counter <= fence_stall_counter - 1;
                else begin
                    fence_stall_counter <= 0;
                    fence_stall_active <= 0;
                end
            end
        end
    end

    assign invalid_inst = ~((IDinstruct  == `INST_NOP)    ||
        ((IDinstruct & `INST_ADD_MASK)   == `INST_ADD)    ||
        ((IDinstruct & `INST_SUB_MASK)   == `INST_SUB)    ||
        ((IDinstruct & `INST_AND_MASK)   == `INST_AND)    ||
        ((IDinstruct & `INST_OR_MASK)    == `INST_OR)     ||
        ((IDinstruct & `INST_XOR_MASK)   == `INST_XOR)    ||
        ((IDinstruct & `INST_SLL_MASK)   == `INST_SLL)    ||
        ((IDinstruct & `INST_SRL_MASK)   == `INST_SRL)    ||
        ((IDinstruct & `INST_SRA_MASK)   == `INST_SRA)    ||
        ((IDinstruct & `INST_SLT_MASK)   == `INST_SLT)    ||
        ((IDinstruct & `INST_SLTU_MASK)  == `INST_SLTU)   ||

        ((IDinstruct & `INST_ANDI_MASK)  == `INST_ANDI)   ||
        ((IDinstruct & `INST_ADDI_MASK)  == `INST_ADDI)   ||
        ((IDinstruct & `INST_SLTI_MASK)  == `INST_SLTI)   ||
        ((IDinstruct & `INST_SLTIU_MASK) == `INST_SLTIU)  ||
        ((IDinstruct & `INST_ORI_MASK)   == `INST_ORI)    ||
        ((IDinstruct & `INST_XORI_MASK)  == `INST_XORI)   ||

        ((IDinstruct & `INST_SLLI_MASK)  == `INST_SLLI)   ||
        ((IDinstruct & `INST_SRLI_MASK)  == `INST_SRLI)   ||
        ((IDinstruct & `INST_SRAI_MASK)  == `INST_SRAI)   ||

        ((IDinstruct & `INST_LB_MASK)    == `INST_LB)     ||
        ((IDinstruct & `INST_LBU_MASK)   == `INST_LBU)    ||
        ((IDinstruct & `INST_LH_MASK)    == `INST_LH)     ||
        ((IDinstruct & `INST_LHU_MASK)   == `INST_LHU)    ||
        ((IDinstruct & `INST_LW_MASK)    == `INST_LW)     ||

        ((IDinstruct & `INST_SB_MASK)    == `INST_SB)     ||
        ((IDinstruct & `INST_SH_MASK)    == `INST_SH)     ||
        ((IDinstruct & `INST_SW_MASK)    == `INST_SW)     ||

        ((IDinstruct & `INST_BEQ_MASK)   == `INST_BEQ)    ||
        ((IDinstruct & `INST_BNE_MASK)   == `INST_BNE)    ||
        ((IDinstruct & `INST_BLT_MASK)   == `INST_BLT)    ||
        ((IDinstruct & `INST_BGE_MASK)   == `INST_BGE)    ||
        ((IDinstruct & `INST_BLTU_MASK)  == `INST_BLTU)   ||
        ((IDinstruct & `INST_BGEU_MASK)  == `INST_BGEU)   ||

        ((IDinstruct & `INST_JAL_MASK)   == `INST_JAL)    ||
        ((IDinstruct & `INST_JALR_MASK)  == `INST_JALR)   ||
        ((IDinstruct & `INST_LUI_MASK)   == `INST_LUI)    ||
        ((IDinstruct & `INST_AUIPC_MASK) == `INST_AUIPC)  ||

        ((IDinstruct & `CSR_INST_MASK)   == `CSRRW_INST)  ||
        ((IDinstruct & `CSR_INST_MASK)   == `CSRRS_INST)  ||
        ((IDinstruct & `CSR_INST_MASK)   == `CSRRC_INST)  ||
        ((IDinstruct & `CSR_INST_MASK)   == `CSRRWI_INST) ||
        ((IDinstruct & `CSR_INST_MASK)   == `CSRRSI_INST) ||
        ((IDinstruct & `CSR_INST_MASK)   == `CSRRCI_INST) ||
        ((IDinstruct & `CSR_INST_MASK)   == `MRET_INST)   ||
        ((IDinstruct & `CSR_INST_MASK)   == `ECALL_INST)  ||
        
        ((IDinstruct & `INST_FENCE_MASK) == `INST_FENCE)  ||
        ((IDinstruct & `INST_SFENCE_MASK)== `INST_SFENCE) ||
        ((IDinstruct & `INST_IFENCE_MASK)== `INST_IFENCE) ||
        ((IDinstruct & `INST_MUL_MASK)   == `INST_MUL)    ||
        ((IDinstruct & `INST_AMOSWAP_W_MASK)  == `INST_AMOSWAP_W)  
        ); 
    
    //fence handling
    assign fence = 
        (((IDinstruct & `INST_FENCE_MASK) == `INST_FENCE) ||
        ((IDinstruct & `INST_SFENCE_MASK)== `INST_SFENCE) ||
        ((IDinstruct & `INST_IFENCE_MASK)== `INST_IFENCE));
  
    //for DMEM mmu
    assign access_is_load_ID =   (((IDinstruct & `INST_LB_MASK)    == `INST_LB)     ||
                                  ((IDinstruct & `INST_LBU_MASK)   == `INST_LBU)    ||
                                  ((IDinstruct & `INST_LH_MASK)    == `INST_LH)     ||
                                  ((IDinstruct & `INST_LHU_MASK)   == `INST_LHU)    ||
                                  ((IDinstruct & `INST_LW_MASK)    == `INST_LW));
    assign access_is_store_ID =  (((IDinstruct & `INST_SB_MASK)    == `INST_SB)     ||
                                  ((IDinstruct & `INST_SH_MASK)    == `INST_SH)     ||
                                  ((IDinstruct & `INST_SW_MASK)    == `INST_SW));
    assign faulting_inst = IDinstruct;
    assign ecall = (^IDinstruct === 1'bx) ? 1'b0 : (IDinstruct == `ECALL_INST);

    //for swap
    assign swap = (IDinstruct & `INST_AMOSWAP_W_MASK)  == `INST_AMOSWAP_W;
endmodule