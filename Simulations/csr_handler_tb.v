`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/13/2025 03:47:36 PM
// Design Name: 
// Module Name: csr_handler_tb
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


module csr_handler_tb;

    reg clk = 0;
    reg rst = 1;

    // Inputs to csr_handler
    reg  [31:0] csr_inst;
    reg  [31:0] csr_rs1;

    reg         csr_wben;
    reg  [11:0] csr_wbaddr;
    reg  [31:0] csr_wbdata;

    // Outputs from csr_handler
    wire [31:0] csr_rresult;
    wire [31:0] csr_data_to_wb;

    // Instantiate DUT
    csr_handler dut (
        .clk(clk),
        .rst(rst),
        .csr_inst(csr_inst),
        .csr_rs1(csr_rs1),
        .csr_wben(csr_wben),
        .csr_wbaddr(csr_wbaddr),
        .csr_wbdata(csr_wbdata),
        .csr_rresult(csr_rresult),
        .csr_data_to_wb(csr_data_to_wb)
    );

    // Clock generator
    always #5 clk = ~clk;

    // Local parameters
    localparam MSTATUS_ADDR = 12'h300;
    localparam CSRRW_OPCODE  = 7'b1110011;
    localparam CSRRW_FUNCT3  = 3'b001;
    localparam CSRRS_FUNCT3  = 3'b010;

    function [31:0] encode_csr_inst(input [2:0] funct3, input [11:0] csr, input [4:0] rs1, input [4:0] rd);
        encode_csr_inst = {csr, rs1, funct3, rd, CSRRW_OPCODE};
    endfunction

    initial begin
        $display("Starting testbench...");
        // Reset
        rst = 1;
        #20;
        rst = 0;
        #5
        // --- TEST 1: CSRRS (read mstatus) ---
        csr_rs1      = 32'h00000000;           // no bits to set
        csr_inst     = encode_csr_inst(CSRRS_FUNCT3, MSTATUS_ADDR, 5'd0, 5'd1);
        csr_wben     = 0;
        csr_wbaddr   = 0;
        csr_wbdata   = 0;

        #10;
        $display("CSRRS result (should read mstatus): 0x%08x", csr_rresult);
        $display("CSRRS data_to_wb (should be mstatus): 0x%08x", csr_data_to_wb);

        // --- TEST 2: CSRRW (write mstatus) ---
        csr_rs1      = 32'hA5A5A5A5;
        csr_inst     = encode_csr_inst(CSRRW_FUNCT3, MSTATUS_ADDR, 5'd1, 5'd2);
        csr_wben     = 1;
        csr_wbaddr   = MSTATUS_ADDR;
        csr_wbdata   = 32'hFFFFFFFF;

        #10;
        $display("CSRRW result (should read old mstatus): 0x%08x", csr_rresult);
        $display("CSRRW data_to_wb (should be rs1): 0x%08x", csr_data_to_wb);

        // --- TEST 3: CSRRS to unknown CSR (should return 0) ---
        csr_rs1      = 32'h00000000;
        csr_inst     = encode_csr_inst(CSRRS_FUNCT3, 12'h305, 5'd0, 5'd1); // non-existent CSR
        csr_wben     = 0;
        csr_wbaddr   = 0;
        csr_wbdata   = 0;

        #10;
        $display("CSRRS (invalid addr) result: 0x%08x", csr_rresult);
        $display("CSRRS (invalid addr) data_to_wb: 0x%08x", csr_data_to_wb);

        $finish;
    end
endmodule

