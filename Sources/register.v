`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2025 01:21:04 PM
// Design Name: 
// Module Name: register
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


module register(
    input wire clk,
    input wire write_enable,
    input wire [4:0] rd, r1, r2,
    input wire [1:0] WBSel, // 0-dmem_out 1-ALU_out 2-PC + 4
    input wire [31:0] PC,   // not +4, need to +4 here
    input wire [31:0] ALU_out,
    input wire [31:0] dmem_out,
    output wire [31:0] rdata1, rdata2,
    
    // debug output
    output wire [31:0] Out0, Out1, Out2, Out3, Out4
);

    // Register file
    reg [31:0] RegData [31:0];

    // Write-back data select
    wire [31:0] wdata;
    assign wdata = (WBSel == 2'b00) ? dmem_out : 
                   (WBSel == 2'b01) ? ALU_out : PC + 4;

    // Ensure x0 is always zero
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            RegData[i] = 0;
    end

    // Write operation
    always @(posedge clk) begin
        if (write_enable && rd != 0)
            RegData[rd] <= wdata;
    end

    // Combinational read
    assign rdata1 = (r1 == 0) ? 32'b0 : RegData[r1];
    assign rdata2 = (r2 == 0) ? 32'b0 : RegData[r2];

    // Debug outputs
    assign Out0 = RegData[0];
    assign Out1 = RegData[1];
    assign Out2 = RegData[2];
    assign Out3 = RegData[3];
    assign Out4 = RegData[4];

endmodule

