`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/08/2025 02:14:14 PM
// Design Name: 
// Module Name: jump_branch_unit
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

module jump_branch_unit( 
    input  wire        clk,
    input  wire        rst,
    input  wire        jump_early,
    input  wire        branch_early,
    input  wire [31:0] immID,
    input  wire        branch_resolved,
    input  wire        actual_taken,
    input  wire [31:0] pc,
    input  wire [2:0]  pht_indexMEM,
    input  wire        csr_branch_signal, // Later flush that disables this

    output wire [31:0] PC_Jump,
    output wire [1:0]  flush,
    output wire        jump_taken,
    output wire [2:0]  pht_index,
    output wire [31:0] PC_saved
    
);

    // gshare predictor
    reg [2:0] GHR;
    reg [1:0] PHT [15:0];
    assign pht_index = pc[4:2] ^ GHR;
    wire predict_taken = branch_early && (PHT[pht_index] >= 2);
    assign PC_saved = pc;
    
    integer i;
    always @(posedge clk) begin
        if(rst) begin
            GHR <= 3'b000;
            for (i = 0; i < 16; i = i + 1)
                PHT[i] <= 2'b01;
        end
        else if (branch_resolved) begin
            // Update PHT
            if (actual_taken && (PHT[pht_indexMEM] != 2'b11))
                PHT[pht_indexMEM] <= PHT[pht_indexMEM] + 1;
            else if (!actual_taken && (PHT[pht_indexMEM] != 2'b00))
                PHT[pht_indexMEM] <= PHT[pht_indexMEM] - 1;

            // Update GHR
            GHR <= {GHR[1:0], actual_taken};
            `ifdef DEBUG
                $display("[BRANCH RESOLVED] GHR: %b | Updating PHT[%0d] => %b | actual_taken = %b", GHR, pht_indexMEM, PHT[pht_indexMEM], actual_taken);
            `endif
        end
        `ifdef DEBUG
            $display("JBU => pc: %h | PCSAVED: %h", pc, PC_saved);
        `endif
    end

    `ifdef DEBUG
        reg branch_early_prev;
        always @(posedge clk) begin
            branch_early_prev <= branch_early;
            if (branch_early && !branch_early_prev) begin
                $display("[PREDICTING] PC = 0x%08h | GHR = %b | pht_index = %b | PHT[%0d] = %b | predict_taken = %b", pc, GHR, pht_index, pht_index, PHT[pht_index], predict_taken);
                $display("csr_branch %b", csr_branch_signal);
            end
        end
    `endif
    
    // Output logic
    assign PC_Jump    = (jump_early || predict_taken) ? immID : 32'h00000000;
    assign flush      = (jump_early || predict_taken) ? 2'b01 : 2'b00;
    assign jump_taken = csr_branch_signal ? 1'b0 : (jump_early || predict_taken);
endmodule
