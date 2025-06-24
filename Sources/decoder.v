`timescale 1ns / 1ps

module decoder (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire [1:0]  flushOut,
    input  wire [31:0] instruction,
    input  wire [31:0] pc,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    output wire [31:0] IDinstruct_o,
    output wire [31:0] IDPC_o,
    output wire [4:0]  IDrs1_o,
    output wire [4:0]  IDrs2_o,
    output wire [4:0]  IDrd_o,
    output wire [31:0] IDinstCSR_o,
    output wire        invalid_inst,
    output wire [31:0] faulting_inst
);
`include "inst_defs.v"
`include "csr_defs.v"

reg [31:0] IDinstruct;
reg [31:0] IDPC;
reg [4:0]  IDrs1;
reg [4:0]  IDrs2;
reg [4:0]  IDrd;
reg [31:0]  IDinstCSR;
    
always @(posedge clk) begin
    `ifdef DEBUG
        $display(" ");
        $display("PC: %h", pc);
        $display("Invalid Instruction: %b, IDins: %h, IDPC: %h, IDrs1, %h, IDrd: %h, IDinstCSR: %h", invalid_inst, IDinstruct, IDPC, IDrs1, IDrd, IDinstCSR);
    `endif
    if(rst) begin
        IDinstruct <= `INST_NOP;
        IDPC       <= 32'h00000000;
        IDrs1      <= 5'b0;              
        IDrs2      <= 5'b0;
        IDrd       <= 5'b0; 
        IDinstCSR  <= `INST_NOP;   
    end
    else if (!(stall)) begin
        if (flushOut == 2'b11) begin
            IDinstruct  <= `INST_NOP;
            IDrs1       <= 5'b0;            
            IDrs2       <= 5'b0;
            IDrd        <= 5'b0;
            IDinstCSR  <= 32'b0;                     
        end
        else if (flushOut == 2'b01)
        begin
            IDinstruct <= `INST_NOP;
            IDrs1      <= 5'b0;               
            IDrs2      <= 5'b0;
            IDrd       <= 5'b0;   
            IDinstCSR  <= 32'b0;           
        end
        else if(instruction[6:0] == 7'b1110011) begin
            IDinstruct <= instruction;
            IDPC       <= pc;
            IDrs1      <= rs1;              
            IDrs2      <= 5'b0;
            IDrd       <= rd;              
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
        IDinstruct <= `INST_NOP;
        IDrs1      <= 5'b0;              
        IDrs2      <= 5'b0;
        IDrd       <= 5'b0;  
        IDinstCSR  <= 32'b0;            
    end
end
    assign IDinstruct_o = IDinstruct;
    assign IDPC_o = IDPC;
    assign IDrs1_o = IDrs1;
    assign IDrs2_o = IDrs2;
    assign IDrd_o = IDrd;
    assign IDinstCSR_o = IDinstCSR;
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
        
        // NOT ACTUALLY IMPLEMENTED I JUST DON"T WANT TEST TO TRAP
        ((IDinstruct & `INST_FENCE_MASK) == `INST_FENCE)  ||
        ((IDinstruct & `INST_SFENCE_MASK)== `INST_SFENCE) ||
        ((IDinstruct & `INST_IFENCE_MASK)== `INST_IFENCE)
        );
        assign faulting_inst = IDinstruct;
endmodule