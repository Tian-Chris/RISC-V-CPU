`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/13/2025 01:01:38 PM
// Design Name: 
// Module Name: csr_handler
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

module csr_handler(
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  flush,
    input  wire [31:0] csr_inst,
    input  wire [31:0] csr_rs1,
    
    //csr write (comes from WB)
    input  wire        csr_wben,
    input  wire [11:0] csr_wbaddr,   //address written
    input  wire [31:0] csr_wbdata,   //data written
    
    output wire        csr_reg_en,
    output wire [31:0] csr_rresult, //result of read
    output wire [31:0] csr_data_to_wb,  //csr_data_to_wb -> WB -> csr_wdata 
    output wire [31:0] csr_addr_to_wb,
    
    //trap
    input  wire [31:0] csr_trapPC,
    input  wire [4:0]  csr_trapID,
    input  wire [31:0] faulting_inst,
    input  wire [31:0] faulting_va_IMEM,
    input  wire [31:0] faulting_va_DMEM,
    output wire        csr_branch_signal,
    output wire [31:0] csr_branch_address,

    //interrupts
    input wire        msip,   
    input wire        mtip,
    //uart
    input wire        meip,
    
    //forwarding
    input wire [31:0] MEMAlu,
    input wire [31:0] WBdmem,
    input wire [31:0] WBAlu,
    input wire [31:0] WBPC,   // not +4, need to +4 here
    input wire [1:0] WBSel,
    input wire [1:0] forwardA,

    //MMU
    output wire [1:0]  priv,
    output wire [31:0] csr_satp,
    output wire [31:0] sstatus_sum
    );
    
`include "csr_defs.v"
//csr read
wire [3:0]  csr_op_type;       // CSR op: DN. RW/I, RS/I, RC/I
wire [11:0] csr_raddr;
wire        csr_ren;
wire [31:0] csr_rdata;
wire [31:0] csr_status;
wire [31:0] zimm;
wire        csr_ecall;
wire        csr_mret;
wire        csr_sret;

// Forwarding values for CSR rs1
wire [31:0] csr_rs1_val;
wire  [1:0] wdata;
assign wdata = (WBSel == 2'b00) ? WBdmem : 
               (WBSel == 2'b01) ? WBAlu : WBPC + 4;
assign csr_rs1_val = forwardA[1] ? MEMAlu : (forwardA[0] ? wdata : csr_rs1);
    

assign csr_op_type = ((csr_inst & `CSR_INST_MASK) == `CSRRW_INST) ? `CSR_OPP_RW :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRS_INST) ? `CSR_OPP_RS :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRC_INST) ? `CSR_OPP_RC :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRWI_INST) ? `CSR_OPP_RWI :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRSI_INST) ? `CSR_OPP_RSI :
                     ((csr_inst & `CSR_INST_MASK) == `CSRRCI_INST) ? `CSR_OPP_RCI : `CSR_OPP_DN;
assign csr_ren     = csr_op_type != `CSR_OPP_DN;
assign csr_reg_en  = csr_op_type != `CSR_OPP_DN;
assign csr_raddr   = csr_inst[31:20];
assign zimm        = csr_inst[19:15];
assign csr_ecall   = csr_inst == `ECALL_INST;
assign csr_mret    = csr_inst == `MRET_INST;
assign csr_sret    = csr_inst == `SRET_INST;

reg  [11:0] csr_addr_EX;
reg  [31:0] csr_rdata_EX;
reg  [11:0] csr_addr_MEM;
reg  [31:0] csr_rdata_MEM;

csr_file csr (
    .clk(clk),
    .rst(rst),
    
    //csr write
    .csr_wen(csr_wben),
    .csr_waddr(csr_wbaddr),
    .csr_wdata(csr_wbdata),
    
    //csr read
    .csr_ren(csr_ren),
    .csr_raddr(csr_raddr),
    .csr_rdata(csr_rdata),
    .csr_status(csr_status),
    
    //exception
    .csr_trapPC(csr_trapPC),
    .csr_trapID(csr_trapID),
    .faulting_inst(faulting_inst),
    .faulting_va_IMEM(faulting_va_IMEM),
    .faulting_va_DMEM(faulting_va_DMEM),
    .csr_ecall(csr_ecall),
    .csr_mret(csr_mret),
    .csr_sret(csr_sret),
    .csr_branch_signal(csr_branch_signal),
    .csr_branch_address(csr_branch_address),
    .csr_addr_EX(csr_addr_EX),
    .csr_rdata_EX(csr_rdata_EX),
    .csr_addr_MEM(csr_addr_MEM),
    .csr_rdata_MEM(csr_rdata_MEM),

    //interrupt
    .mtip(mtip),
    .msip(msip),
    .meip(meip),

    //mmu
    .satp_o(csr_satp),
    .priv_o(priv),
    .sstatus_sum(sstatus_sum)
);

//read
reg [31:0] csr_rdata_clocked;
reg [31:0] output_data;
reg [11:0] csr_raddr_clocked;
reg [31:0] csr_rdata_forward;

always @(*) begin
    if(csr_raddr == csr_addr_EX)
        csr_rdata_forward = csr_rdata_EX;
    else if(csr_raddr == csr_addr_MEM)
        csr_rdata_forward = csr_rdata_MEM;
    else
        csr_rdata_forward = csr_rdata;
end

always @(posedge clk) begin
    `ifdef DEBUG
        $display("CSR Write => WBSel: %b | WBdmem: %h | WBAlu: %h | MEMAlu: %h | WBPC+4: %h | wdata: %h | forwardA: %b | csr_rs1: %h | csr_rs1_val: %h",
            WBSel, WBdmem, WBAlu, MEMAlu, WBPC + 4, wdata, forwardA, csr_rs1, csr_rs1_val);
    `endif 

    if(rst) begin
        csr_rdata_clocked <= 32'b0;
        csr_raddr_clocked <= 32'b0;
        output_data       <= 32'b0;
    end 
    else begin
        csr_rdata_clocked <= csr_rdata_forward;
        csr_raddr_clocked <= csr_raddr;
        case(csr_op_type)
            `CSR_OPP_RW:  output_data <= csr_rs1_val;
            `CSR_OPP_RS:  output_data <= csr_rs1_val | csr_rdata_forward;
            `CSR_OPP_RC:  output_data <= ~csr_rs1_val & csr_rdata_forward;
            `CSR_OPP_RWI: output_data <= zimm; 
            `CSR_OPP_RSI: output_data <= zimm | csr_rdata_forward;
            `CSR_OPP_RCI: output_data <= ~zimm & csr_rdata_forward;
            default:      output_data <= 32'b0;
        endcase
    end
end

assign csr_data_to_wb = output_data;
assign csr_addr_to_wb = csr_raddr_clocked;
assign csr_rresult    = csr_rdata_clocked;

always @(*) begin
    if(flush == 2'b11) begin
        csr_addr_EX <= 0;
        csr_rdata_EX <= 0;
    end
    else begin
        csr_addr_EX   <= csr_raddr_clocked;
        csr_rdata_EX  <= output_data;
    end
end
always @(posedge clk) begin
    if(flush == 2'b11 || rst) begin
        csr_addr_MEM <= 0;
        csr_rdata_MEM <= 0;
    end
    else begin
        csr_addr_MEM  <= csr_addr_EX;
        csr_rdata_MEM <= csr_rdata_EX;
    end
end
endmodule