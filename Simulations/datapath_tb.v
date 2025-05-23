`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2025 04:28:03 PM
// Design Name: 
// Module Name: datapath_tb
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

module datapath_tb;

    // Inputs
    reg [31:0] instruct;
    reg brEq;
    reg brLt;

    // Outputs
    wire [2:0] funct3;
    wire PCSel;
    wire Reg_WEn;
    wire [2:0] imm_gen_sel;
    wire branch_signed;
    wire ALU_BSel;
    wire ALU_ASel;
    wire [3:0] ALU_Sel;
    wire dmemRW;
    wire [1:0] Reg_WBSel;

    // Instantiate the Unit Under Test (UUT)
    datapath uut (
        .instruct(instruct),
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

    task display_outputs;
        reg [6:0] opcode;
        reg [4:0] rd, rs1, rs2;
        reg [2:0] f3;
        reg [6:0] funct7;
    begin
        opcode = instruct[6:0];
        rd     = instruct[11:7];
        f3     = instruct[14:12];
        rs1    = instruct[19:15];
        rs2    = instruct[24:20];
        funct7 = instruct[31:25];
    
        $display("\n=== Instruction @ time %0t ===", $time);
        $display("Instruction : 0x%h", instruct);
        $display(" Fields      : funct7=%07b | rs2=%02d | rs1=%02d | funct3=%03b | rd=%02d | opcode=%07b",
                 funct7, rs2, rs1, f3, rd, opcode);
        
        $display(" Control Signals:");
        $display("  funct3       = %3b", funct3);
        $display("  PCSel        = %1b", PCSel);
        $display("  Reg_WEn      = %1b", Reg_WEn);
        $display("  imm_gen_sel  = %3b", imm_gen_sel);
        $display("  branch_signed= %1b", branch_signed);
        $display("  ALU_BSel     = %1b", ALU_BSel);
        $display("  ALU_ASel     = %1b", ALU_ASel);
        $display("  ALU_Sel      = %4b", ALU_Sel);
        $display("  dmemRW       = %1b", dmemRW);
        $display("  Reg_WBSel    = %2b", Reg_WBSel);
        $display("==============================\n");
    end
    endtask


    initial begin
        $display("Starting datapath testbench...");
        brEq = 0;
        brLt = 0;

        // R-type: add x1, x2, x3
        // opcode = 0110011, funct3 = 000, funct7 = 0000000
        instruct = 32'b0000000_00011_00010_000_00001_0110011;
        #10 display_outputs;

        // I-type: addi x1, x2, 5
        instruct = 32'b000000000101_00010_000_00001_0010011;
        #10 display_outputs;

        // S-type: sw x1, 0(x2)
        instruct = 32'b0000000_00001_00010_010_00000_0100011;
        #10 display_outputs;

        // B-type: beq x1, x2, label
        instruct = 32'b0000000_00010_00001_000_00000_1100011;
        brEq = 1; // set condition true
        #10 display_outputs;

        // J-type: jal x1, offset
        instruct = 32'b00000000000100000000_00001_1101111;
        #10 display_outputs;

        // I-type: jalr x1, 0(x2)
        instruct = 32'b000000000000_00010_000_00001_1100111;
        #10 display_outputs;

        // U-type: auipc x1, 0x1000
        instruct = 32'b000100000000_00001_0010111;
        #10 display_outputs;

        $display("Testbench finished.");
        $stop;
    end
endmodule
