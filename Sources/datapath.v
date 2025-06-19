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
    input wire [31:0] instruct, //ID
    input wire brEq,
    input wire brLt,
    input wire [4:0] MEMrd,
    input wire [4:0] WBrd,
    input wire jump_taken,
    output reg jump_early,
    output reg branch_early,
    output reg [2:0] funct3,
    output reg PCSel,
    output reg Reg_WEn, 
    output reg [2:0] imm_gen_sel, // 0-5 = I-J
    output reg branch_signed,
    output reg ALU_BSel, //0 = rdata1, 1 = PC + 4
    output reg ALU_ASel, //0 = rdata2, 1 = imm
    output reg [3:0] ALU_Sel, //0-8 add-shift_right
    output reg dmemRW, //1 = write, 0 = read
    output reg [1:0] Reg_WBSel, // 0 = dmem, 1 = alu, 2 = PC+4
    output reg [1:0] forwardA,
    output reg [1:0] forwardB,
    output reg [1:0] forwardDmem,
    output reg [1:0] forwardBranchA,
    output reg [1:0] forwardBranchB,
    output wire IDmemRead,

    // load hazard detection
    output reg [1:0] Reg_WBSelID,
    output reg [1:0] Reg_WBSelEX,
    
    //flush
    input  wire [1:0] flushIn,
    output reg [1:0] flushOut,
    
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
    
    wire [8:0] nbiID; //nine_bit_instruction
    wire [8:0] nbiEX; //nine_bit_instruction
    wire [8:0] nbiMEM; //nine_bit_instruction
    wire [8:0] nbiWB; //nine_bit_instruction

    reg [6:0] exControl;
    reg [31:0] instructEX;
    reg [31:0] instructMEM;
    reg [31:0] instructWB;
    reg [1:0] Reg_WBSelMEM;
    reg [1:0] Reg_WBSelWB;
    
    reg BrEqMEM;
    reg BrLTMEM;
    
    //forwarding
    reg [1:0] uses_reg; // 1 is rs2 0 is rs1
    wire [4:0] raw_rs1_EX = instructEX[19:15];
    wire [4:0] raw_rs2_EX = instructEX[24:20];
    wire [4:0] rs1_EX = uses_reg[0] ? raw_rs1_EX : 5'd0;
    wire [4:0] rs2_EX = uses_reg[1] ? raw_rs2_EX : 5'd0;
    reg Reg_WEnID;
    reg Reg_WEnEX;
    reg Reg_WEnMEM;
    reg Reg_WEnWB;
    reg dmemRWEX;
    
    
    always @(*) begin
        forwardA = 2'b00;
        forwardB = 2'b00;
        forwardDmem = 2'b00;
        forwardBranchA = 2'b00;
        forwardBranchB = 2'b00;

        if (nbiEX[4:0] == 5'b11000) begin
            // Forward for branch comparison only
            if (Reg_WEnMEM && MEMrd != 0 && MEMrd == rs1_EX)
                forwardBranchA = 2'b10;
            else if (Reg_WEnWB && WBrd != 0 && WBrd == rs1_EX)
                forwardBranchA = 2'b01;
    
            if (Reg_WEnMEM && MEMrd != 0 && MEMrd == rs2_EX)
                forwardBranchB = 2'b10;
            else if (Reg_WEnWB && WBrd != 0 && WBrd == rs2_EX)
                forwardBranchB = 2'b01;
        end
        else begin
            // Normal ALU forwarding
            if (Reg_WEnMEM && MEMrd != 0 && MEMrd == rs1_EX)
                forwardA = 2'b10;
            else if (Reg_WEnWB && WBrd != 0 && WBrd == rs1_EX)
                forwardA = 2'b01;
    
            if (dmemRWEX == 1) begin
                if (Reg_WEnMEM && MEMrd != 0 && MEMrd == rs2_EX)
                    forwardDmem = 2'b10;
                else if (Reg_WEnWB && WBrd != 0 && WBrd == rs2_EX)
                    forwardDmem = 2'b01;
            end
            else begin
                if (Reg_WEnMEM && MEMrd != 0 && MEMrd == rs2_EX)
                    forwardB = 2'b10;
                else if (Reg_WEnWB && WBrd != 0 && WBrd == rs2_EX)
                    forwardB = 2'b01;
            end
        end
    end
    
    
    initial begin
        Reg_WBSelID  = 2'b11;
        Reg_WBSelEX  = 2'b11;
    end
    
    assign IDmemRead = (Reg_WBSelID == 2'b00);
    
    //           funct7        funct3          oppcode (without last 2 bits)
    assign nbiID = {instruct[30], instruct[14:12], instruct[6:2]};
    assign nbiEX = {instructEX[30], instructEX[14:12], instructEX[6:2]};
    assign nbiMEM = {instructMEM[30], instructMEM[14:12], instructMEM[6:2]};
    assign nbiWB = {instructWB[30], instructWB[14:12], instructWB[6:2]};

    //Early jump/branch
    always @(*) begin
    if (nbiID[4:0] == 5'b11011)
        begin
        jump_early = 1;
        branch_early = 0;
    end else
        begin
        jump_early = 0;
        end
    if (nbiID[4:0] == 5'b11000)
    begin
        branch_early = 1;
        jump_early = 0;
    end else
        branch_early = 0;
    end
    
    // =====
    // clocks
    // =====
    //ex
    always @(posedge clk) begin
        instructEX <= instruct;
        Reg_WEnEX <= Reg_WEnID;
        Reg_WBSelEX <= Reg_WBSelID;
    end
    //mem
    always @(posedge clk) begin
        instructMEM <= instructEX;
        Reg_WEnMEM <= Reg_WEnEX;
        Reg_WBSelMEM <= Reg_WBSelEX;
        BrEqMEM <= brEq;
        BrLTMEM <= brLt;
    end
    //wb
    always @(posedge clk) begin
        instructWB <= instructMEM;
        Reg_WEnWB <= Reg_WEnMEM;
        Reg_WBSelWB <= Reg_WBSelMEM;
    end

    always @(*) begin
        if(PCSel)
            flushOut = 2'b11;
        else
            flushOut = flushIn;
    end
    always @(*) begin
        Reg_WEn = Reg_WEnWB;
        Reg_WBSel = Reg_WBSelWB;
        //======
        //  ID
        //======
        casez(nbiID)
        //==Arithmetic==
            //==R-type==
            //oppcode: 0110011 -> 01100 || immSel XXX(000 (i))
            9'b?_???_01100: imm_gen_sel = 3'b000; //all R type

            //== I-type ==
            //oppcode: 0010011 -> 00100 immSel 000(i)
            9'b?_000_00100: imm_gen_sel = 3'b000; //addi note no subi exists
            9'b?_111_00100: imm_gen_sel = 3'b000; //andi
            9'b?_110_00100: imm_gen_sel = 3'b000; //ori
            9'b?_100_00100: imm_gen_sel = 3'b000; //xori
            
            //I*-type start
            9'b0_001_00100: imm_gen_sel = 3'b001; //sli
            9'b0_101_00100: imm_gen_sel = 3'b001; //sri
            9'b1_101_00100: imm_gen_sel = 3'b001; //srai
            
            9'b?_010_00100: imm_gen_sel = 3'b000; //slti
            9'b?_011_00100: imm_gen_sel = 3'b000; //sltiu
            
        //== Memory==
            // I-type
            //oppcode: 0000011 -> 00000 || immSel 000(i)
            9'b?_???_00000: imm_gen_sel = 3'b000; //all loads lb lh lhu lw 
            
            // S-type
            //oppcode: 0100011 -> 01000 || immSel 010(s)
            9'b?_???_01000: imm_gen_sel = 3'b010; //all saves
            
        //== Control==
            // B-type
            //oppcode: 1100011 -> 11000 immSel 011(s)
            9'b?_???_11000: imm_gen_sel = 3'b011; //all branchs bne blt bltu etc
            
            // J-type
            //oppcode: 1101111 -> 11011 || immSel 101(j)
            9'b?_???_11011: imm_gen_sel = 3'b101; //jal
            
            //I-type
            //oppcode 1100111 -> 11001 || immsel 000(i)
            9'b?_000_11001: imm_gen_sel = 3'b000; //jalr
            
        //== Other==
            // U-type
            // 0010111-> 00101
            9'b?_???_00101: imm_gen_sel = 3'b100; //aiupc
            9'b?_???_01101: imm_gen_sel = 3'b100; // LUI
            default: imm_gen_sel = 3'b000;
        endcase
        
    //for forwarding mask
       casez(nbiEX)
            9'b?_???_01100: uses_reg = 2'b11; //all arith
            //== I-type ==
            9'b?_???_00100: uses_reg = 2'b01; //i and i* type arith
        //== Memory==     
            // I-type
            9'b?_???_00000: uses_reg = 2'b01; //all load
            // S-type
            9'b?_???_01000: uses_reg = 2'b11; //all store
        //== Control==
            // B-type
            9'b?_???_11000: uses_reg = 2'b11; //all store
            // J-type
            9'b?_???_11011: uses_reg = 2'b00; //jal
            //I-type
            9'b?_???_11001: uses_reg = 2'b01; //jalr
        //== Other==
            // U-type
            9'b?_???_00101: uses_reg = 2'b00; //aiupc
            9'b?_???_01101: uses_reg = 2'b00; // LUI
            9'b?_???_11100: uses_reg = 2'b01; //csr
            default: uses_reg = 2'b00;
       endcase
       
    //for forwarding
       casez(nbiID)
        //==Arithmetic==
            //== R-type ==
            9'b?_???_01100: Reg_WEnID = 1'b1; //all arith
            //== I-type ==
            9'b?_???_00100: Reg_WEnID = 1'b1; //i and i* type arith
        //== Memory==     
            // I-type
            9'b?_???_00000: Reg_WEnID = 1'b1; //all load
            // S-type
            9'b?_???_01000: Reg_WEnID = 1'b0; //all store
        //== Control==
            // B-type
            9'b?_???_11000: Reg_WEnID = 1'b0; //all store
            // J-type
            9'b?_???_11011: Reg_WEnID = 1'b1; //jal
            //I-type
            9'b?_???_11001: Reg_WEnID = 1'b1; //jalr
        //== Other==
            // U-type
            9'b?_???_00101: Reg_WEnID = 1'b1; //aiupc
            9'b?_???_01101: Reg_WEnID = 1'b1; // LUI
            9'b?_???_11100: Reg_WEnID = 1'b1; // csr
            default: Reg_WEnID = 1'b0;
        endcase
        
    //for load hazard detection
        casez(nbiID)
        //==Arithmetic==
            //== R-type ==
            9'b?_???_01100: Reg_WBSelID = 2'b01; //all arith
            //== I-type ==
            9'b?_???_00100: Reg_WBSelID = 2'b01; //i and i* type arith
        //== Memory==     
            // I-type
            9'b?_???_00000: Reg_WBSelID = 2'b00; //all load
            // S-type
            9'b?_???_01000: Reg_WBSelID = 2'b00; //all store
        //== Control==
            // B-type
            9'b?_???_11000: Reg_WBSelID = 2'b00; //all store
            // J-type
            9'b?_???_11011: Reg_WBSelID = 2'b11; //jal
            //I-type
            9'b?_???_11001: Reg_WBSelID = 2'b11; //jalr
        //== Other==
            // U-type
            9'b?_???_00101: Reg_WBSelID = 2'b01; //aiupc
            9'b?_???_01101: Reg_WBSelID = 2'b01; // LUI
            default: Reg_WBSelID = 2'b11;
        endcase 
        //======
        //  Ex
        //======
        casez(nbiEX)
        //==Arithmetic==
            //==R-type==
            //oppcode: 0110011 -> 01100
            //BranchSign  ALUASel  ALUBSel  ALUSel 
            //X           0 (A)    0 (B)    Opperation 
            9'b0_000_01100: exControl = 7'b000_0000; //add
            9'b1_000_01100: exControl = 7'b000_0001; //sub
            9'b0_111_01100: exControl = 7'b000_0010; //and
            9'b0_110_01100: exControl = 7'b000_0011; //or
            9'b0_100_01100: exControl = 7'b000_0100; //xor
            9'b0_001_01100: exControl = 7'b000_0101; //sl
            9'b0_101_01100: exControl = 7'b000_0110; //sr
            9'b1_101_01100: exControl = 7'b000_0111; //sra
            9'b0_010_01100: exControl = 7'b000_1001; //slt
            9'b0_011_01100: exControl = 7'b000_1000; //sltu
            
            //== I-type ==
            //oppcode: 0010011 -> 00100
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  000 (I)  X           0 (A)    1 (imm)  Opperation  0 (Read)  01 (ALU)
            9'b?_000_00100: exControl = 7'b001_0000; //addi note no subi exists
            9'b?_111_00100: exControl = 7'b001_0010; //andi
            9'b?_110_00100: exControl = 7'b001_0011; //ori
            9'b?_100_00100: exControl = 7'b001_0100; //xori
            
            //I*-type start
            9'b0_001_00100: exControl = 7'b001_0101; //sli
            9'b0_101_00100: exControl = 7'b001_0110; //sri
            9'b1_101_00100: exControl = 7'b001_0111; //srai
            
            9'b?_010_00100: exControl = 7'b001_1001; //slti
            9'b?_011_00100: exControl = 7'b001_1000; //sltiu
            
        //== Memory==
                    
            // I-type
            //oppcode: 0000011 -> 00000
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  000(i)   X           0 (A)    1 (imm)  ADD         0 (Read)  00 (dmem)
            9'b?_???_00000: exControl = 7'b001_0000; //all loads lb lh lhu lw
            
            // S-type
            //oppcode: 0100011 -> 01000
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //0(read)   010(s)   X           0 (A)    1 (imm)  ADD         1 (Write) XX
            9'b?_???_01000: exControl = 7'b001_0000;// all stores
            
        //== Control==

            // B-type
            //oppcode: 1100011 -> 11000
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //0(read)   011(s)   depends     1 (PC)   1 (imm)  ADD         0 (Read)  XX
            9'b?_000_11000: exControl = 7'b011_0000; //beq PC bit handled elsewhere
            9'b?_001_11000: exControl = 7'b011_0000; //bne
            9'b?_100_11000: exControl = 7'b011_0000; //blt
            9'b?_110_11000: exControl = 7'b111_0000; //bltu
            9'b?_101_11000: exControl = 7'b011_0000; //bge
            9'b?_111_11000: exControl = 7'b111_0000; //bgeu
            
            // J-type
            //oppcode: 1101111 -> 11011
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  101(j)   X           1 (PC)   1 (imm)  ADD         0 (Read)  11 (PC + 4)
            9'b?_???_11011: exControl = 7'b011_0000; //jal
            
            //I-type
            //oppcode 1100111 -> 11001
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  000(i)   X           0 (a)    1 (imm)  ADD         0 (Read)  11 (PC + 4)
            9'b?_000_11001: exControl = 7'b001_0000; //jalr
            
        //== Other==
            // U-type
            // 0010111-> 00101
            //RegWEn    immSel   BranchSign  ALUASel  ALUBSel  ALUSel      dmemRW    RegWBSel
            //1(write)  100(U)   X           1 (PC)   1 (imm)  ADD         0 (Read)  01 (ALU)
            9'b?_???_00101: exControl = 7'b011_0000; //aiupc
            9'b?_???_01101: exControl = 7'b111_1011; // LUI
            default: exControl = 7'b000_0000;
        endcase

        branch_signed = exControl[6];
        ALU_ASel      = exControl[5];
        ALU_BSel      = exControl[4];
        ALU_Sel       = exControl[3:0];

        //======
        // MEM
        //======
        casez(nbiMEM)
            9'b?_???_01000: dmemRW = 1'b1; //stores
            default: dmemRW = 1'b0;
        endcase
        casez(nbiEX)
            9'b?_???_01000: dmemRWEX = 1'b1; //stores
            default: dmemRWEX = 1'b0;
        endcase
        funct3 = instructMEM[14:12];
        if (nbiMEM[4:0] == 5'b11011 || nbiMEM[4:0] == 5'b11001) begin
            if(jump_taken)
                PCSel = 0;
            else
                PCSel = 1; // JAL or JALR
            branch_resolved = 0;
            mispredict = 0;
        end else if (nbiMEM[4:0] == 5'b11000) begin
            case (funct3)
                3'b000: PCSel = BrEqMEM;
                3'b001: PCSel = !BrEqMEM;
                3'b100: PCSel = BrLTMEM;
                3'b110: PCSel = BrLTMEM;
                3'b101: PCSel = !BrLTMEM;
                3'b111: PCSel = !BrLTMEM;
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
        end else begin
            mispredict = 0;
            branch_resolved = 0;
            PCSel = 0;
            actual_taken = 0;
        end
    end     
    //debug
    `ifdef DEBUG
        assign Reg_WEnMEMo = Reg_WEnMEM;
        assign Reg_WEnWBo = Reg_WEnWB;
        assign rs1_EXo = rs1_EX;
        assign rs2_EXo = rs2_EX;
    `endif
endmodule