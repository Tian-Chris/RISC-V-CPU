`timescale 1ns / 1ps

module csr_file (
    input  wire        clk,
    input  wire        rst,
     
    //csr write
    input  wire        csr_wen,
    input  wire [11:0] csr_waddr,
    input  wire [31:0] csr_wdata,
    
    //csr read
    input  wire        csr_ren,
    input  wire [11:0] csr_raddr,
    output wire [31:0] csr_rdata,
    output wire [31:0] csr_status

);
`include "csr_defs.v"

//all unused mvendorid marchid mimpid mhartid
reg [31:0] csrzero;  

//current
reg [31:0] mstatus_f;
reg [31:0] mstatush_f;
reg [31:0] misa_f;
reg [31:0] medeleg_f;
reg [31:0] mideleg_f;
reg [31:0] mie_f;
reg [31:0] mtvec_f;
reg [31:0] mscratch_f;
reg [31:0] mepc_f;
reg [31:0] mcause_f;
reg [31:0] mtval_f;
reg [31:0] mip_f;
reg [31:0] mcycle_f;
reg [31:0] mcycleh_f;

//current
reg [31:0] mstatus_c;
reg [31:0] mstatush_c;
reg [31:0] misa_c;
reg [31:0] medeleg_c;
reg [31:0] mideleg_c;
reg [31:0] mie_c;
reg [31:0] mtvec_c;
reg [31:0] mscratch_c;
reg [31:0] mepc_c;
reg [31:0] mcause_c;
reg [31:0] mtval_c;
reg [31:0] mip_c;
reg [31:0] mcycle_c;
reg [31:0] mcycleh_c;

//read
reg  [31:0] rdata;
always @(*) begin
    rdata = 32'b0;
    if(csr_ren) begin
    case(csr_raddr)
        `mstatus_ADDR:   rdata = (mstatus_c  & `mstatus_MASK);
        `mstatush_ADDR:  rdata = (mstatush_c & `mstatush_MASK);
        `misa_ADDR:      rdata = (misa_c     & `misa_MASK);
        `mepc_ADDR:      rdata = (mepc_c     & `mepc_MASK);
        `mcause_ADDR:    rdata = (mcause_c   & `mcause_MASK);
        `mtvec_ADDR:     rdata = (mtvec_c    & `mtvec_MASK);
        `mip_ADDR:       rdata = (mip_c      & `mip_MASK);
        `mie_ADDR:       rdata = (mie_c      & `mie_MASK);
        `mcycle_ADDR:    rdata = (mcycle_c   & `mcycle_MASK);
        `mcycleh_ADDR:   rdata = (mcycleh_c  & `mcycleh_MASK);
        `mscratch_ADDR:  rdata = (mscratch_c & `mscratch_MASK);
        `mtval_ADDR:     rdata = (mtval_c    & `mtval_MASK);
        `medeleg_ADDR:   rdata = (medeleg_c  & `medeleg_MASK);
        `mideleg_ADDR:   rdata = (mideleg_c  & `mideleg_MASK);
        default:         rdata = 32'b0;
    endcase
    end
end
assign csr_rdata = rdata;
assign csr_status = mstatus_c;

//write back
always @(*) begin
    mstatus_f  = mstatus_c;
    mstatush_f = mstatush_c;
    misa_f     = misa_c;
    medeleg_f  = medeleg_c;
    mideleg_f  = mideleg_c;
    mie_f      = mie_c;
    mtvec_f    = mtvec_c;
    mscratch_f = mscratch_c;
    mepc_f     = mepc_c;
    mcause_f   = mcause_c;
    mtval_f    = mtval_c;
    mip_f      = mip_c;
    mcycle_f   = mcycle_c;
    mcycleh_f  = mcycleh_c;

    if(csr_wen) begin
    case(csr_waddr)
        `mstatus_ADDR:   mstatus_f  = (mstatus_f  & ~`mstatus_MASK)  | (csr_wdata & `mstatus_MASK);
        `mstatush_ADDR:  mstatush_f = (mstatush_f & ~`mstatush_MASK) | (csr_wdata & `mstatush_MASK);
        `misa_ADDR:      misa_f     = (misa_f     & ~`misa_MASK)     | (csr_wdata & `misa_MASK);
        `mepc_ADDR:      mepc_f     = (mepc_f     & ~`mepc_MASK)     | (csr_wdata & `mepc_MASK);
        `mcause_ADDR:    mcause_f   = (mcause_f   & ~`mcause_MASK)   | (csr_wdata & `mcause_MASK);
        `mtvec_ADDR:     mtvec_f    = (mtvec_f    & ~`mtvec_MASK)    | (csr_wdata & `mtvec_MASK);
        `mip_ADDR:       mip_f      = (mip_f      & ~`mip_MASK)      | (csr_wdata & `mip_MASK);
        `mie_ADDR:       mie_f      = (mie_f      & ~`mie_MASK)      | (csr_wdata & `mie_MASK);
        `mcycle_ADDR:    mcycle_f   = (mcycle_f   & ~`mcycle_MASK)   | (csr_wdata & `mcycle_MASK);
        `mcycleh_ADDR:   mcycleh_f  = (mcycleh_f  & ~`mcycleh_MASK)  | (csr_wdata & `mcycleh_MASK);
        `mscratch_ADDR:  mscratch_f = (mscratch_f & ~`mscratch_MASK) | (csr_wdata & `mscratch_MASK);
        `mtval_ADDR:     mtval_f    = (mtval_f    & ~`mtval_MASK)    | (csr_wdata & `mtval_MASK);
        `medeleg_ADDR:   medeleg_f  = (medeleg_f  & ~`medeleg_MASK)  | (csr_wdata & `medeleg_MASK);
        `mideleg_ADDR:   mideleg_f  = (mideleg_f  & ~`mideleg_MASK)  | (csr_wdata & `mideleg_MASK);
        default:         csrzero    = 32'b0;
    endcase
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        csrzero    <= 32'b0;
        mstatus_c  <= 32'b0;
        mstatush_c <= 32'b0;
        misa_c     <= 32'b0;
        medeleg_c  <= 32'b0;
        mideleg_c  <= 32'b0;
        mie_c      <= 32'b0;
        mtvec_c    <= 32'b0;
        mscratch_c <= 32'b0;
        mepc_c     <= 32'b0;
        mcause_c   <= 32'b0;
        mtval_c    <= 32'b0;
        mip_c      <= 32'b0;
        mcycle_c   <= 32'b0;
        mcycleh_c  <= 32'b0;
    end else
    begin
        mstatus_c  <= mstatus_f;
        mstatush_c <= mstatush_f;
        misa_c     <= misa_f;
        medeleg_c  <= medeleg_f;
        mideleg_c  <= mideleg_f;
        mie_c      <= mie_f;
        mtvec_c    <= mtvec_f;
        mscratch_c <= mscratch_f;
        mepc_c     <= mepc_f;
        mcause_c   <= mcause_f;
        mtval_c    <= mtval_f;
        mip_c      <= mip_f;
        mcycle_c   <= mcycle_f;
        mcycleh_c  <= mcycleh_f;
    end
end

endmodule
