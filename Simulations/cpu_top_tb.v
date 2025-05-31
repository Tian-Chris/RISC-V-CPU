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

  // Instantiate the CPU Top
  cpu_top uut (
    .clk(clk),
    .reset(reset),
    .pc(pc),
    .instruction(instruction),
    .alu_out(alu_out),
    .imm(imm),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .brEq(brEq),
    .brLt(brLt),
    .Reg_WEn(Reg_WEn),
    .PCSel(PCSel),
    .stall(stall),
    .Reg_WBSelID(Reg_WBSelID),
    .Reg_WBSelEX(Reg_WBSelEX),
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
    .dmem_out(dmem_out)
  );

  // Clock generation
  initial clk = 0;
  always #10 clk = ~clk;

  // Reset pulse
  initial begin
    reset = 1;
    #20;
    reset = 0;
  end

  // Golden output checking
  integer file, i, code;
  reg [8*64:1] line;
  reg [31:0] expected;
  reg [31:0] actual;
  reg pass;

  integer cycle;
  initial begin
    // Wait until x11 equals 0x0000c0de
      // Wait for x11 == 0x0000c0de or timeout after 1000 cycles
      for (cycle = 0; cycle < 50; cycle = cycle + 1) begin
        if (Out11 === 32'h0000c0de) begin
          cycle = 1000;
        end
        #20;  // wait one clock cycle (assuming 20ns period)
      end
    
    pass = 1;
    file = $fopen("U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test.golden", "r");
    if (file == 0) begin
      $display("ERROR: Could not open golden file:");
    end

    for (i = 0; i < 32; i = i + 1) begin
      if ($fgets(line, file)) begin
        if (line == "\n" || line == "" || line[8*1-1:0] == "#") begin
          $display("Skipping x%0d (blank or comment)", i);
        end

        code = $sscanf(line, "%h", expected);
        if (code != 1) begin
          $display("Skipping x%0d (could not parse line)", i);
        end

        actual = Out[i];  // Access output wire
        if (actual !== expected) begin
          $display("Mismatch at x%0d: expected %h, got %h", i, expected, actual);
          pass = 0;
        end
      end else begin
        $display("Skipping x%0d (missing line)", i);
      end
    end

    $fclose(file);
    if (pass)
      $display("[TEST PASSED]");
    else
      $display("[TEST FAILED]");
	$finish;
  end
endmodule