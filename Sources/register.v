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
    output wire [31:0] rdata1, rdata2
     
    // debug output
    `ifdef DEBUG
     , output wire [31:0] Out0, Out1, Out2, Out3, Out4, Out5, Out6, Out7, Out8, Out9, 
                      Out10, Out11, Out12, Out13, Out14, Out15, Out16, Out17, Out18,
                      Out19, Out20, Out21, Out22, Out23, Out24, Out25, Out26, Out27,
                      Out28, Out29, Out30, Out31
     `endif
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
       RegData[0] = 0;
    end

    // Write operation
    always @(posedge clk) begin
        if (write_enable && rd != 0)
            RegData[rd] <= wdata;
    end

    // Combinational read
    assign rdata1 = (r1 == 0) ? 32'b0 :
                ((r1 == rd) && write_enable && rd != 0) ? wdata : RegData[r1];

    assign rdata2 = (r2 == 0) ? 32'b0 :
                ((r2 == rd) && write_enable && rd != 0) ? wdata : RegData[r2];


    // Debug outputs
    `ifdef DEBUG
        assign Out0 = RegData[0];     assign Out1 = RegData[1];     assign Out2 = RegData[2];     assign Out3 = RegData[3];
        assign Out4 = RegData[4];     assign Out5 = RegData[5];     assign Out6 = RegData[6];     assign Out7 = RegData[7];
        assign Out8 = RegData[8];     assign Out9 = RegData[9];     assign Out10 = RegData[10];   assign Out11 = RegData[11];
        assign Out12 = RegData[12];   assign Out13 = RegData[13];   assign Out14 = RegData[14];   assign Out15 = RegData[15];
        assign Out16 = RegData[16];   assign Out17 = RegData[17];   assign Out18 = RegData[18];   assign Out19 = RegData[19];
        assign Out20 = RegData[20];   assign Out21 = RegData[21];   assign Out22 = RegData[22];   assign Out23 = RegData[23];
        assign Out24 = RegData[24];   assign Out25 = RegData[25];   assign Out26 = RegData[26];   assign Out27 = RegData[27];
        assign Out28 = RegData[28];   assign Out29 = RegData[29];   assign Out30 = RegData[30];   assign Out31 = RegData[31];
    `endif
endmodule

