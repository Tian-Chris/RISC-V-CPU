`timescale 1ns / 1ps

module jump_branch_unit_tb;

    // Inputs
    reg clk;
    reg jump_early;
    reg branch_early;
    reg [31:0] immID;
    reg branch_resolved;
    reg actual_taken;
    reg [31:0] pc;
    reg [2:0] pht_indexMEM;

    // Outputs
    wire [31:0] PC_Jump;
    wire [1:0]  flush;
    wire        jump_taken;
    wire [2:0]  pht_index;

    // Instantiate the Unit Under Test (UUT)
    jump_branch_unit uut (
        .clk(clk),
        .jump_early(jump_early),
        .branch_early(branch_early),
        .immID(immID),
        .branch_resolved(branch_resolved),
        .actual_taken(actual_taken),
        .pc(pc),
        .pht_indexMEM(pht_indexMEM),
        .PC_Jump(PC_Jump),
        .flush(flush),
        .jump_taken(jump_taken),
        .pht_index(pht_index)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock
    end

    // Test sequence
    initial begin
        $display("\n===== GShare Branch Predictor Testbench =====");
        immID = 32'hABCD1234;
        jump_early = 0;
        branch_early = 0;
        branch_resolved = 0;
        actual_taken = 0;
        pc = 32'h00000010;
        pht_indexMEM = 0;

        #10;

        // ==== First Prediction (should NOT predict taken) ====
        branch_early = 1;
        #10;
        branch_early = 0;

        // ==== First Resolution: actual_taken = 1 ====
        actual_taken = 1;
        branch_resolved = 1;
        pht_indexMEM = uut.pht_index;
        #10;
        branch_resolved = 0;

        // ==== Second Prediction ====
        pc = 32'h00000010;
        branch_early = 1;
        #10;
        branch_early = 0;

        // ==== Second Resolution: actual_taken = 1 ====
        actual_taken = 1;
        branch_resolved = 1;
        pht_indexMEM = uut.pht_index;
        #10;
        branch_resolved = 0;

        // ==== Third Prediction ====
        pc = 32'h00000010;
        branch_early = 1;
        #10;
        branch_early = 0;

        // ==== Third Resolution: actual_taken = 1 ====
        actual_taken = 1;
        branch_resolved = 1;
        pht_indexMEM = uut.pht_index;
        #10;
        branch_resolved = 0;

        // ==== Fourth Prediction: PHT should now be saturated, predict taken ====
        pc = 32'h00000010;
        branch_early = 1;
        #10;
        branch_early = 0;
        
        actual_taken = 0;
        branch_resolved = 1;
        #10; branch_resolved = 0; #10;
        
        actual_taken = 0;
        branch_resolved = 1;
        #10; branch_resolved = 0; #10;
        
        actual_taken = 0;
        branch_resolved = 1;
        #10; branch_resolved = 0; #10;

        // ==== First Prediction (should NOT predict taken) ====
        branch_early = 1;
        #10;
        branch_early = 0;

        // ==== First Resolution: actual_taken = 1 ====
        actual_taken = 1;
        branch_resolved = 1;
        pht_indexMEM = uut.pht_index;
        #10;
        branch_resolved = 0;

        // ==== Second Prediction ====
        pc = 32'h00000010;
        branch_early = 1;
        #10;
        branch_early = 0;

        // ==== Second Resolution: actual_taken = 1 ====
        actual_taken = 1;
        branch_resolved = 1;
        pht_indexMEM = uut.pht_index;
        #10;
        branch_resolved = 0;

        // ==== Third Prediction ====
        pc = 32'h00000010;
        branch_early = 1;
        #10;
        branch_early = 0;

        // ==== Third Resolution: actual_taken = 1 ====
        actual_taken = 1;
        branch_resolved = 1;
        pht_indexMEM = uut.pht_index;
        #10;
        branch_resolved = 0;

        // ==== Fourth Prediction: PHT should now be saturated, predict taken ====
        pc = 32'h00000010;
        branch_early = 1;
        #10;
        branch_early = 0;
        
        actual_taken = 0;
        branch_resolved = 1;
        #10; branch_resolved = 0; #10;
        
        actual_taken = 0;
        branch_resolved = 1;
        #10; branch_resolved = 0; #10;
        
        actual_taken = 0;
        branch_resolved = 1;
        #10; branch_resolved = 0; #10;
        // ==== Reset and simulate not-taken ====
        actual_taken = 0;
        branch_resolved = 1;
        pht_indexMEM = uut.pht_index;
        #10;
        branch_resolved = 0;

        $display("===== Simulation Complete =====");
        $finish;
    end

endmodule
