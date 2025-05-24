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
  wire [31:0] Out0, Out1, Out2, Out3, Out4, dmem_out;


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
    .Out0(Out0),
    .Out1(Out1),
    .Out2(Out2),
    .Out3(Out3),
    .Out4(Out4),
    .dmem_out(dmem_out)
  );

  // Clock generation
  initial clk = 0;
  always #10 clk = ~clk; // 100 MHz clock (10 ns period)

  // Reset sequence
  initial begin
    reset = 1;
    #20;
    reset = 0;
  end

  // Simulation duration and waveform dump
  initial begin
    $display("Starting CPU simulation...");

    // Optional: Enable waveform generation
    $dumpfile("cpu_top_tb.vcd");
    $dumpvars(0, cpu_top_tb);

    // Run for a specific time or until a condition
    #5000; // Adjust as needed to let enough instructions execute
    $display("Ending simulation.");
    $finish;
  end

  // Optional runtime monitor
  always @(posedge clk) begin
    $display("Time: %0t | PC: 0x%08x | Inst: 0x%08x | ALU_Out: 0x%08x | RegWEn: %b",
      $time, pc, instruction, alu_out, Reg_WEn);
  end

endmodule

//addi x1, x0, 5        # x1 = 5
//addi x2, x0, 5        # x2 = 5
//beq x1, x2, 8         # if (x1 == x2) skip next 2 instructions (8 bytes)
//addi x3, x0, 100      # skipped
//addi x4, x0, 101      # skipped
//addi x5, x0, 55       # executed
//bne x1, x2, 8         # not taken (x1 == x2), so x6 is assigned
//addi x6, x0, 66       # executed
//jal x0, 8             # jump over the next instruction (unconditional)
//addi x7, x0, 77       # skipped
//addi x8, x0, 88       # executed
