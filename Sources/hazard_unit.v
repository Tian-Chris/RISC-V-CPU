`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2025 03:02:07 PM
// Design Name: 
// Module Name: hazard_unit
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


module hazard_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire [4:0] IFrs1,
    input  wire [4:0] IFrs2,
    input  wire [4:0] IDrd,
    input  wire IDmemRead,
    input  wire csr_branch_signal,

    //flush
    input  wire PCSel,
    input  wire jump_taken,

    //MMU Stall
    input  wire stall_IMEM,
    input  wire stall_DMEM,

    output reg [3:0] hazard_signal,

    //exception
    input  wire        pc_misaligned,
    input  wire [31:0] faulting_inst_i, 
    input  wire        invalid_inst,
    input  wire        instr_fault_mmu_DMEM, load_fault_mmu_DMEM, store_fault_mmu_DMEM,
    input  wire        instr_fault_mmu_IMEM, load_fault_mmu_IMEM, store_fault_mmu_IMEM,
    input  wire [31:0] faulting_va_IMEM_i,
    output wire [31:0] faulting_inst_o,
    output wire [31:0] faulting_va_IMEM_o,
    output wire [4:0]  trapID
);
    `include "inst_defs.v"
    `include "csr_defs.v"
    `ifdef DEBUG_ALL
        `define DEBUG_HAZARD
        `define DEBUG_EXCEPT
    `endif
    //Stall
    always @(*) begin
        if(PCSel || csr_branch_signal || trapID != `EXCEPT_DO_NOTHING)
            hazard_signal = `FLUSH_ALL;
        else if(jump_taken)
            hazard_signal = `FLUSH_EARLY;
        else if(stall_IMEM || stall_DMEM)
            hazard_signal = `STALL_MMU; 
        else if(IDmemRead && (IDrd != 0) && ((IDrd == IFrs1) || (IDrd == IFrs2)))
            hazard_signal = `STALL_EARLY; 
        else
            hazard_signal = `HS_DN;
        `ifdef DEBUG_HAZARD
            $display("===========  HAZARD  ===========");
            $display("hazard_signal: %b", hazard_signal);
        `endif
    end

    //Exceptions 
    wire PC_ID;
    wire PC_EX;
    wire PC_MEM;
    wire invalid_inst_EX;
    wire invalid_inst_MEM;
    wire instr_fault_mmu_IMEM_EX;
    wire load_fault_mmu_IMEM_EX;
    wire store_fault_mmu_IMEM_EX;
    wire instr_fault_mmu_IMEM_MEM;
    wire load_fault_mmu_IMEM_MEM;
    wire store_fault_mmu_IMEM_MEM;
    wire [31:0] faulting_inst_EX;
    wire [31:0] faulting_inst_MEM;
    wire [31:0] faulting_va_IMEM_EX;
    wire [31:0] faulting_va_IMEM_MEM;

    localparam EXBUNDLE_WIDTH = 1 + 1 + 1 + 1 + 1 + 32 + 32; 
    localparam MEMBUNDLE_WIDTH = 1 + 1 + 1 + 1 + 1 + 32 + 32; 
    wire [EXBUNDLE_WIDTH-1:0] EXBUNDLE = {PC_ID, invalid_inst, instr_fault_mmu_IMEM, load_fault_mmu_IMEM, store_fault_mmu_IMEM, faulting_inst_i, faulting_va_IMEM_i};
    wire [EXBUNDLE_WIDTH-1:0] EXBUNDLE_OUT;
    wire [MEMBUNDLE_WIDTH-1:0] MEMBUNDLE = {PC_EX, invalid_inst_EX, instr_fault_mmu_IMEM_EX, load_fault_mmu_IMEM_EX, store_fault_mmu_IMEM_EX, faulting_inst_EX, faulting_va_IMEM_EX};
    wire [MEMBUNDLE_WIDTH-1:0] MEMBUNDLE_OUT;
    Pipe #(.STAGE(`STAGE_ID), .WIDTH(1)) PIPE_ID (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(pc_misaligned), .out_data(PC_ID)
        );
    Pipe #(.STAGE(`STAGE_EX), .WIDTH(EXBUNDLE_WIDTH)) PIPE_EX (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(EXBUNDLE), .out_data(EXBUNDLE_OUT)
        );
    Pipe #(.STAGE(`STAGE_EX), .WIDTH(MEMBUNDLE_WIDTH)) PIPE_MEM (
        .clk(clk), .rst(rst), .hazard_signal(hazard_signal), .in_data(MEMBUNDLE), .out_data(MEMBUNDLE_OUT)
        );
    assign {PC_EX, invalid_inst_EX, instr_fault_mmu_IMEM_EX, load_fault_mmu_IMEM_EX, store_fault_mmu_IMEM_EX, faulting_inst_EX, faulting_va_IMEM_EX} = EXBUNDLE_OUT; 
    assign {PC_MEM, invalid_inst_MEM, instr_fault_mmu_IMEM_MEM, load_fault_mmu_IMEM_MEM, store_fault_mmu_IMEM_MEM, faulting_inst_MEM, faulting_va_IMEM_MEM} = MEMBUNDLE_OUT; 


    always @(posedge clk) begin
        `ifdef DEBUG_EXCEPT
            $display("=========== EXCEPT ===========");
            $display("trapID: %h", trapID);
            $display("MMU Faults: instr_fault_mmu = %h | load_fault_mmu = %h | store_fault_mmu = %h", instr_fault_mmu, load_fault_mmu, store_fault_mmu);
            $display("PCs:        PC_ID = %h | PC_EX = %h | PC_MEM = %h", PC_ID, PC_EX, PC_MEM);
            $display("Invalid:    invalid_inst_EX = %b | invalid_inst_MEM = %b", invalid_inst_EX, invalid_inst_MEM);
            $display("Fault Inst: faulting_inst_EX = %b | faulting_inst_MEM = %b", faulting_inst_EX, faulting_inst_MEM);
            $display("Instr:      instr_fault_mmu_IMEM_EX = %b | instr_fault_mmu_IMEM_MEM = %b", instr_fault_mmu_IMEM_EX, instr_fault_mmu_IMEM_MEM);
            $display("Load:       load_fault_mmu_IMEM_EX  = %b | load_fault_mmu_IMEM_MEM  = %b", load_fault_mmu_IMEM_EX, load_fault_mmu_IMEM_MEM);
            $display("Store:      store_fault_mmu_IMEM_EX = %b | store_fault_mmu_IMEM_MEM = %b", store_fault_mmu_IMEM_EX, store_fault_mmu_IMEM_MEM);
            $display("VA:         faulting_va_IMEM_EX = %h | faulting_va_IMEM_MEM = %h", faulting_va_IMEM_EX, faulting_va_IMEM_MEM);
        `endif
    end

    wire instr_fault_mmu = instr_fault_mmu_DMEM | instr_fault_mmu_IMEM_MEM;
    wire load_fault_mmu  = load_fault_mmu_DMEM  | load_fault_mmu_IMEM_MEM;
    wire store_fault_mmu = store_fault_mmu_DMEM | store_fault_mmu_IMEM_MEM;

    assign faulting_va_IMEM_o  = faulting_va_IMEM_MEM; 
    assign faulting_inst_o     = faulting_inst_MEM;
    assign trapID = PC_MEM          ? `EXCEPT_MISALIGNED_PC    :
                invalid_inst_MEM    ? `EXCEPT_ILLEGAL_INST     : 
                instr_fault_mmu     ? `EXCEPT_INST_PAGE_FAULT  : 
                load_fault_mmu      ? `EXCEPT_LOAD_PAGE_FAULT  :
                store_fault_mmu     ? `EXCEPT_STORE_PAGE_FAULT : `EXCEPT_DO_NOTHING;
endmodule
