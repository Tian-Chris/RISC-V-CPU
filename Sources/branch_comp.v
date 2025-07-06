`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/21/2025 11:24:30 AM
// Design Name: 
// Module Name: branch_comp
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


module branch_comp(
    input wire clk,
    input wire sign_select,
    input wire [31:0] rdata1,
    input wire [31:0] rdata2,
    input wire [1:0] forwardBranchA,
    input wire [1:0] forwardBranchB,
    input wire [31:0] MEMAlu,
    input wire [31:0] WBdmem,
    input wire [31:0] WBAlu,
    input wire [31:0] WBPC,
    input wire [1:0] WBSel,

    //csr forward
    input wire MEM_csr_reg_en,
    input wire WB_csr_reg_en,
    input wire [31:0] MEM_csr_rresult,
    input wire [31:0] WB_csr_rresult,
    
    output wire equal,
    output wire less_than
    );
    `ifdef DEBUG_ALL
        `define DEBUG_BRANCH
    `endif

    wire signed [31:0] r1_s;
    wire signed [31:0] r2_s;
    wire [31:0] wdata;
    wire [31:0] memdata;
    wire [31:0] a, b;

    
    assign wdata =  (WB_csr_reg_en) ? WB_csr_rresult :
                    (WBSel == 2'b00) ? WBdmem : 
                    (WBSel == 2'b01) ? WBAlu : WBPC + 4;
    assign memdata = MEM_csr_reg_en ? MEM_csr_rresult : MEMAlu;

    assign a = forwardBranchA[1] ? memdata : (forwardBranchA[0] ? wdata : rdata1);
    assign b = forwardBranchB[1] ? memdata : (forwardBranchB[0] ? wdata : rdata2);
    
    assign r1_s = $signed(a);
    assign r2_s = $signed(b);
    
    assign less_than = (!sign_select) ? (r1_s < r2_s) : (a < b);
    assign equal     = (a == b);
    always @(posedge clk) begin
    `ifdef DEBUG_BRANCH
        $display("===========  BRANCH  ===========");
        $display("WBSel      : %b", WBSel);
        $display("WBdmem     : %h", WBdmem);
        $display("WBAlu      : %h", WBAlu);
        $display("WBPC + 4   : %h", WBPC + 4);
        $display("Selected wdata  : %h", wdata);
        $display("forwardBranchA  : %b", forwardBranchA);
        $display("forwardBranchB  : %b", forwardBranchB);
        $display("rdata1     : %h", rdata1);
        $display("rdata2     : %h", rdata2);
        $display("Selected a : %h", a);
        $display("Selected b : %h", b);
        $display("a (signed) : %d", r1_s);
        $display("b (signed) : %d", r2_s);
        $display("sign_select  : %b", sign_select);
        $display("less_than  : %b", less_than);
        $display("equal      : %b", equal);
        $display("=============================");
    `endif
end
    
endmodule
