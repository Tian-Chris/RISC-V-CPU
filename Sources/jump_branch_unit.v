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
    input  wire        jump_early,
    input  wire        branch_early,
    input  wire [31:0] immID,
    input  wire        branch_resolved,
    input  wire        actual_taken,
    input  wire [31:0] pc,
    input  wire [2:0]  pht_indexMEM,

    output wire [31:0] PC_Jump,
    output wire [1:0]  flush,
    output wire        jump_taken,
    output wire [2:0]  pht_index
);

    //gshare
    reg [2:0] GHR;
    reg [1:0] PHT [0:7];
    assign pht_index = pc[4:2] ^ GHR;
    wire predict_taken = branch_early && (PHT[pht_index] >= 2);

    integer i;
    initial begin
        GHR <= 3'b000;
        for (i = 0; i < 8; i = i + 1)
            PHT[i] <= 2'b01; 
    end

    always @(posedge clk) begin
        if (branch_resolved) begin
            // Update PHT
            if (actual_taken && PHT[pht_indexMEM] != 2'b11)
                PHT[pht_indexMEM] <= PHT[pht_indexMEM] + 1;
            else if (!actual_taken && PHT[pht_indexMEM] != 2'b00)
                PHT[pht_indexMEM] <= PHT[pht_indexMEM] - 1;

            // Update GHR
            GHR <= {GHR[1:0], actual_taken};
        end
    end
    
    //makes PC jump
    assign PC_Jump    = (jump_early || predict_taken) ? immID : 32'h00000000;
    assign flush      = (jump_early || predict_taken) ? 2'b01 : 2'b00;
    assign jump_taken = (jump_early || predict_taken);
endmodule
