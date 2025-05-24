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
    input wire [31:0] instruct,
    input wire brEq,
    input wire brLt,
    
    output reg [2:0] funct3,
    output reg PCSel,
    output reg Reg_WEn, 
    output reg [2:0] imm_gen_sel, // 0-5 = I-J
    output reg branch_signed,
    output reg ALU_BSel, //0 = rdata1, 1 = PC + 4
    output reg ALU_ASel, //0 = rdata2, 1 = imm
    output reg [3:0] ALU_Sel, //0-8 add-shift_right
    output reg dmemRW, //1 = write, 0 = read
    output reg [1:0] Reg_WBSel // 0 = dmem, 1 = alu, 2 = PC+4
    );
    
    wire [8:0] nbi; //nine_bit_instruction
    reg [13:0] control; //14 bit control
    
    //           funct7        funct3          oppcode (without last 2 bits)
    assign nbi = {instruct[30], instruct[14:12], instruct[6:2]};
    
    
    //PCSel is added later
    always @(*) begin //could also be clocked
        funct3 = instruct[14:12];
        
        casez(nbi)
        //Control: PCSel_RegWEn_immSel_BranchSign_ALUBSel_ALUASel_ALUSel_dmemRW_RegWBSel
        //Control:    1     1     3       1          1      1       4       1      2
    
        //==Arithmetic==
        
            //==R-type==
            //oppcode: 0110011 -> 01100
            //RegWEn    immSel  BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  XXX     X           0 (A)    0 (B)    Opperation  0 (Read)  01 (ALU)
            9'b0_000_01100: control = 14'b1_000_000_0000_0_01; //add
            9'b1_000_01100: control = 14'b1_000_000_0001_0_01; //sub
            9'b0_111_01100: control = 14'b1_000_000_0010_0_01; //and
            9'b0_110_01100: control = 14'b1_000_000_0011_0_01; //or
            9'b0_100_01100: control = 14'b1_000_000_0100_0_01; //xor
            9'b0_001_01100: control = 14'b1_000_000_0101_0_01; //sl
            9'b0_101_01100: control = 14'b1_000_000_0110_0_01; //sr
            9'b1_101_01100: control = 14'b1_000_000_0111_0_01; //sra
            9'b0_010_01100: control = 14'b1_000_000_1000_0_01; //slt
            9'b0_011_01100: control = 14'b1_000_000_1001_0_01; //sltsigned
            
            //== I-type ==
            //oppcode: 0010011 -> 00100
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  000 (I)  X           0 (A)    1 (imm)  Opperation  0 (Read)  01 (ALU)
            9'b?_000_00100: control = 14'b1_000_001_0000_0_01; //addi note no subi exists
            9'b?_111_00100: control = 14'b1_000_001_0010_0_01; //andi
            9'b?_110_00100: control = 14'b1_000_001_0011_0_01; //ori
            9'b?_100_00100: control = 14'b1_000_001_0100_0_01; //xori
            
            //I*-type start
            9'b0_001_01100: control = 14'b1_001_001_0101_0_01; //sli
            9'b0_101_01100: control = 14'b1_001_001_0110_0_01; //sri
            9'b1_101_01100: control = 14'b1_001_001_0111_0_01; //srai
            
            9'b0_010_01100: control = 14'b1_000_001_1000_0_01; //slti
            9'b0_011_01100: control = 14'b1_000_001_1001_0_01; //sltisigned
            
        //== Memory==
                    
            // I-type
            //oppcode: 0000011 -> 00000
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  000(i)   X           0 (A)    1 (imm)  ADD         0 (Read)  00 (dmem)
            9'b0_000_00000: control = 14'b1_000_001_0000_0_00; //dmem handles size //lb
            9'b0_100_00000: control = 14'b1_000_001_0000_0_00; //lb unsigned
            9'b0_001_00000: control = 14'b1_000_001_0000_0_00; //lh
            9'b0_101_00000: control = 14'b1_000_001_0000_0_00; //lhu
            9'b0_010_00000: control = 14'b1_000_001_0000_0_00; //lw
            
            // S-type
            //oppcode: 0100011 -> 01000
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //0(read)   010(s)   X           0 (A)    1 (imm)  ADD         1 (Write) XX
            9'b?_000_01000: control = 14'b0_010_001_0000_100; //store byte //dmem handles size
            9'b?_001_01000: control = 14'b0_010_001_0000_100; //store halfword 
            9'b?_010_01000: control = 14'b0_010_001_0000_100; //store word
            
        //== Control==

            // B-type
            //oppcode: 1100011 -> 11000
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //0(read)   011(s)   depends     1 (PC)   1 (imm)  ADD         0 (Read)  XX
            9'b?_000_11000: control = 14'b0_011_011_0000_000; //beq PC bit handled elsewhere
            9'b?_001_11000: control = 14'b0_011_011_0000_000; //bne
            9'b?_100_11000: control = 14'b0_011_011_0000_000; //blt
            9'b?_110_11000: control = 14'b0_011_111_0000_000; //bltu
            9'b?_101_11000: control = 14'b0_011_011_0000_000; //bge
            9'b?_111_11000: control = 14'b0_011_111_0000_000; //bgeu
            
            // J-type
            //oppcode: 1101111 -> 11011
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  101(j)   X           1 (PC)   1 (imm)  ADD         0 (Read)  11 (PC + 4)
            9'b?_???_11011: control = 14'b1_101_011_0000_011; //jal
            
            //I-type
            //oppcode 1100111 -> 11001
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  000(i)   X           0 (a)    1 (imm)  ADD         0 (Read)  11 (PC + 4)
            9'b?_000_11001: control = 14'b1_000_001_0000_011; //jalr
            
        //== Other==
            // U-type
            // 0010111-> 00101
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  111(U)   X           1 (PC)   1 (imm)  ADD         0 (Read)  01 (ALU)
            9'b?_???_00101: control = 14'b1_111_011_0000_001; //aiupc
            
            //LUI not sure how to implement leaving blank for now
            
            //pretty sure this does nothing since REGW is 0 and dmemW is 0 so it should just do nothing
            default: control = 14'b0_000_0000_000;
        endcase
        if (nbi[4:0] == 5'b11011 || nbi[4:0] == 5'b11001) begin
            PCSel = 1; // JAL or JALR
        end else if (nbi[4:0] == 5'b11000) begin
            case (funct3)
                3'b000: PCSel = brEq;
                3'b001: PCSel = !brEq;
                3'b100: PCSel = brLt;
                3'b110: PCSel = brLt;
                3'b101: PCSel = !brLt;
                3'b111: PCSel = !brLt;
                default: PCSel = 0;
            endcase
        end else begin
            PCSel = 0;
        end
        
        Reg_WEn       = control[13];
        imm_gen_sel   = control[12:10];
        branch_signed = control[9];
        ALU_ASel      = control[8];
        ALU_BSel      = control[7];
        ALU_Sel       = control[6:3];
        dmemRW        = control[2];
        Reg_WBSel     = control[1:0];
        
    end
endmodule
