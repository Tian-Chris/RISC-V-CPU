`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/23/2025 10:44:35 AM
// Design Name: 
// Module Name: cpu_top_tb
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
module cpu_top_tb;

  // Inputs
  reg clk;
  reg reset;

  // Debug Outputs
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
  wire [31:0] dmem_out;
  wire stall;
  wire [1:0] Reg_WBSelID;
  wire [1:0] Reg_WBSelEX;
  wire [31:0] MEMrdata2;
  wire [31:0] dmempreo;
  wire [31:0] forwardAo;
  wire [31:0] forwardBo;
  wire [31:0] MEMAluo;
  wire [31:0] wdatao;
  wire Reg_WEnMEMo;
  wire Reg_WEnWBo;
  wire [4:0] rs1_EXo;
  wire [4:0] rs2_EXo;
  wire [4:0] MEMrdo;
  wire [4:0] WBrdo;
  // Register file outputs (x0 to x31)
  wire [31:0] Out [0:31];
  wire [1:0] flush;
  wire [2:0] phto;
  // Bind each output explicitly for now (depends on your cpu_top port list)
  wire [31:0] Out0 = Out[0];
  wire [31:0] Out1 = Out[1];
  wire [31:0] Out2 = Out[2];
  wire [31:0] Out3 = Out[3];
  wire [31:0] Out4 = Out[4];
  wire [31:0] Out5 = Out[5];
  wire [31:0] Out6 = Out[6];
  wire [31:0] Out7 = Out[7];
  wire [31:0] Out8 = Out[8];
  wire [31:0] Out9 = Out[9];
  wire [31:0] Out10 = Out[10];
  wire [31:0] Out11 = Out[11];
  wire [31:0] Out12 = Out[12];
  wire [31:0] Out13 = Out[13];
  wire [31:0] Out14 = Out[14];
  wire [31:0] Out15 = Out[15];
  wire [31:0] Out16 = Out[16];
  wire [31:0] Out17 = Out[17];
  wire [31:0] Out18 = Out[18];
  wire [31:0] Out19 = Out[19];
  wire [31:0] Out20 = Out[20];
  wire [31:0] Out21 = Out[21];
  wire [31:0] Out22 = Out[22];
  wire [31:0] Out23 = Out[23];
  wire [31:0] Out24 = Out[24];
  wire [31:0] Out25 = Out[25];
  wire [31:0] Out26 = Out[26];
  wire [31:0] Out27 = Out[27];
  wire [31:0] Out28 = Out[28];
  wire [31:0] Out29 = Out[29];
  wire [31:0] Out30 = Out[30];
  wire [31:0] Out31 = Out[31];
  wire        ecall;
  // Instantiate the CPU Top
  cpu_top DUT (
    .clk(clk),
    .rst(reset),
    .pco(pc),
    .instructiono(instruction),
    .alu_outo(alu_out),
    .immo(imm),
    .rdata1o(rdata1),
    .rdata2o(rdata2),
    .brEqo(brEq),
    .brLto(brLt),
    .Reg_WEno(Reg_WEn),
    .PCSelo(PCSel),
    .stallo(stall),
    .Reg_WBSelIDo(Reg_WBSelID),
    .Reg_WBSelEXo(Reg_WBSelEX),
    .MEMrdata2O(MEMrdata2),
    .dmempreo(dmempreo),
    .forwardAo(forwardAo),
    .forwardBo(forwardBo),
    .MEMAluo(MEMAluo),
    .wdatao(wdatao),    
    .Reg_WEnMEMo(Reg_WEnMEMo),
    .Reg_WEnWBo(Reg_WEnWBo),
    .rs1_EXo(rs1_EXo),
    .rs2_EXo(rs2_EXo),
    .MEMrdo(MEMrdo),
    .WBrdo(WBrdo),
    .flushOuto(flush),
    .phto(phto),
    .Out0(Out[0]),
    .Out1(Out[1]),
    .Out2(Out[2]),
    .Out3(Out[3]),
    .Out4(Out[4]),
    .Out5(Out[5]),
    .Out6(Out[6]),
    .Out7(Out[7]),
    .Out8(Out[8]),
    .Out9(Out[9]),
    .Out10(Out[10]),
    .Out11(Out[11]),
    .Out12(Out[12]),
    .Out13(Out[13]),
    .Out14(Out[14]),
    .Out15(Out[15]),
    .Out16(Out[16]),
    .Out17(Out[17]),
    .Out18(Out[18]),
    .Out19(Out[19]),
    .Out20(Out[20]),
    .Out21(Out[21]),
    .Out22(Out[22]),
    .Out23(Out[23]),
    .Out24(Out[24]),
    .Out25(Out[25]),
    .Out26(Out[26]),
    .Out27(Out[27]),
    .Out28(Out[28]),
    .Out29(Out[29]),
    .Out30(Out[30]),
    .Out31(Out[31]),
    .dmem_out(dmem_out),
    .ecall(ecall)
  );
  reg [8*100:1] memfiles [1:5];
  integer i;
  integer done;
  integer cycle;
    // Clock generation
  initial clk = 0;
  always #10 clk = ~clk;


  initial begin
    memfiles[1] = "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test1.mem";
    memfiles[2] = "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test2.mem";
    memfiles[3] = "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test3.mem";
    memfiles[4] = "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test4.mem";
    memfiles[5] = "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test5.mem";

    i = 1;
    done = 0;

    while (i <= 5 && done == 0) begin
      $display("========== Running Test %0d ==========", i);

      // Load hex memory file
      $readmemh(memfiles[i], DUT.IMEM.inst_mem);

      // Apply reset
      reset = 1;
      #50;
      reset = 0;

      // Run for up to 1000 cycles
      cycle = 0;
      while (cycle < 1000 && done == 0) begin
        #20;
        cycle = cycle + 1;
    
        if (Out17 === 32'd93 && Out3 == 32'b01) begin
            #40;
              if (Out10 === 32'd0) begin
                $display("[TEST %0d PASSED]", i);
                              $display("");
    
              end else begin
                $display("[TEST %0d FAILED] gp (x3) = %0d (0x%h)", i, Out10, Out10);
                                $display("");
    
              end
              done = 1;
            end
      end

      if (done == 0) begin
        $display("[TEST %0d TIMEOUT] No result after 1000 cycles.", i);
                $display("");
      end

      done = 0; // Reset done for next test
      i = i + 1;
    end

    $finish;
  end
endmodule