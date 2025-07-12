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
    input  wire        clk,
    input  wire        rst,
    input  wire        write_enable,
    input  wire [4:0]  rd, r1, r2,
    input  wire [1:0]  WBSel, // 0-dmem_out 1-ALU_out 2-PC + 4
    input  wire [31:0] PC,   // not +4, need to +4 here
    input  wire [31:0] ALU_out,
    input  wire [31:0] dmem_out,
    output wire        WB_csr_wben,
    output wire [11:0] WB_csr_wbaddr, 
    output wire [31:0] WB_csr_wbdata, 
    input  wire        WB_csr_reg_en,
    input  wire [31:0] WB_csr_rresult, 
    input  wire [31:0] WB_csr_data_to_wb, 
    input  wire [31:0] WB_csr_addr_to_wb, 
    output wire [31:0] rdata1, rdata2
     
    `ifdef DEBUG
     , output wire [31:0] Out0, Out1, Out2, Out3, Out4, Out5, Out6, Out7, Out8, Out9, 
                      Out10, Out11, Out12, Out13, Out14, Out15, Out16, Out17, Out18,
                      Out19, Out20, Out21, Out22, Out23, Out24, Out25, Out26, Out27,
                      Out28, Out29, Out30, Out31
     `endif
);
    `ifdef DEBUG_ALL
        `define DEBUG_REGISTER
    `endif

    reg [31:0] RegData [31:0];
    wire write_enable_I;
    // Write-back data select
    wire [31:0] wdata;
    assign wdata = (WB_csr_reg_en == 1'b1) ? WB_csr_rresult :
                    (WBSel == 2'b00) ? dmem_out : 
                   (WBSel == 2'b01) ? ALU_out : PC + 4;
    //csr writes to rd
    assign write_enable_I = (WB_csr_reg_en == 1'b1) ? 1'b1 : write_enable;
    //wb to csr reg 
    assign WB_csr_wben   = WB_csr_reg_en;
    assign WB_csr_wbaddr = (WB_csr_reg_en == 1) ? WB_csr_addr_to_wb : 1'b0;
    assign WB_csr_wbdata = (WB_csr_reg_en == 1) ? WB_csr_data_to_wb : 1'b0;

    always @(posedge clk) begin
        if(rst) begin
            RegData[0]  = 0;
            RegData[3]  = 32'hXXXXXXXX;   // x3 = gp
            RegData[10] = 32'hXXXXXXXX;   // x10 = a0
            RegData[17] = 32'hXXXXXXXX;   // x17 = a7
        end
        else begin
            `ifdef DEBUG_REGISTER
                $display("===========  REGISTER  ===========");
                $display("rd: %b,r1: %b,r2: %b, wdata: %h, WBSel: %b, write_enable: %b, write_enable_I: %b, WB_csr_reg_en: %b, WB_csr_rresult: %h, WB_csr_data_to_wb: %h, WB_csr_wbaddr: %h", rd, r1, r2, wdata, WBSel, write_enable, write_enable_I, WB_csr_reg_en, WB_csr_rresult, WB_csr_data_to_wb, WB_csr_wbaddr);
                $display("rdata1: %h, rdata2: %h", rdata1, rdata2);

            `endif
            if (write_enable_I && rd != 0)
                RegData[rd] <= wdata;
        end
    end
    assign rdata1 = (r1 == 0) ? 32'b0 :
                    ((r1 == rd) && write_enable_I && rd != 0) ? wdata : RegData[r1];
    assign rdata2 = (r2 == 0) ? 32'b0 :
                    ((r2 == rd) && write_enable_I && rd != 0) ? wdata : RegData[r2];

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

