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
    output wire [31:0] csr_status,
    
    //exception
    input  wire [31:0] csr_trapPC,
    input  wire [4:0]  csr_trapID,
    input  wire [31:0] faulting_inst,
    input  wire        csr_ecall,
    input  wire        csr_mret,
    input  wire        csr_sret,
    
    //trap branch
    output reg         csr_branch_signal,
    output reg [31:0]  csr_branch_address,
    
    //trap branch forwarding
    input  wire [11:0] csr_addr_EX,
    input  wire [31:0] csr_rdata_EX,
    input  wire [11:0] csr_addr_MEM,
    input  wire [31:0] csr_rdata_MEM,
    input  wire [31:0] faulting_va_IMEM,
    input  wire [31:0] faulting_va_DMEM,

    //MMU
    output wire [1:0]  priv_o,
    output wire [31:0] satp_o,
    output wire        sstatus_sum,

    //interrupts
    input wire        msip,   
    input wire        mtip,
    //uart
    input wire        meip
);
`include "csr_defs.v"

//all unused mvendorid marchid mimpid mhartid
reg [31:0] csrzero;  

//future
reg [1:0]  priv_f;
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
//supervisor
reg [31:0] stvec_f;
reg [31:0] sscratch_f;
reg [31:0] sepc_f;
reg [31:0] scause_f;
reg [31:0] stval_f;
reg [31:0] satp_f;

//current
reg [1:0]  priv_c;
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
//supervisor
reg [31:0] stvec_c;
reg [31:0] sscratch_c;
reg [31:0] sepc_c;
reg [31:0] scause_c;
reg [31:0] stval_c;
reg [31:0] satp_c;

//read
reg  [31:0] rdata;
always @(*) begin
    rdata = 32'b0; //do i need this?
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
        
        `sstatus_ADDR:   rdata = (mstatus_c  & `sstatus_MASK);
        `sie_ADDR:       rdata = (mie_c      & `sie_MASK);
        `sip_ADDR:       rdata = (mip_c      & `sip_MASK);

        `stvec_ADDR:     rdata = (stvec_c    & `stvec_MASK);
        `sscratch_ADDR:  rdata = (sscratch_c & `sscratch_MASK);
        `sepc_ADDR:      rdata = (sepc_c     & `sepc_MASK);
        `scause_ADDR:    rdata = (scause_c   & `scause_MASK);
        `stval_ADDR:     rdata = (stval_c    & `stval_MASK);
        `satp_ADDR:      rdata = (satp_c     & `satp_MASK);
        default:         rdata = 32'h00000000;
    endcase
    end
end

assign csr_rdata = rdata;
assign csr_status = mstatus_c;

//write back
always @(*) begin
    if(csr_wen) begin
    `ifdef DEBUG_CSR
        $display("CSR WRITE: addr = 0x%03h, data = 0x%08h", csr_waddr, csr_wdata);
    `endif
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

        `sstatus_ADDR:   mstatus_f  = (mstatus_f  & ~`sstatus_MASK)  | (csr_wdata & `sstatus_MASK);
        `sie_ADDR:       mie_f      = (mie_f      & ~`sie_MASK)      | (csr_wdata & `sie_MASK);
        `sip_ADDR:       mip_f      = (mip_f      & ~`sip_MASK)      | (csr_wdata & `sip_MASK);       

        `stvec_ADDR:     stvec_f    = (stvec_f    & ~`stvec_MASK)    | (csr_wdata & `stvec_MASK);
        `sscratch_ADDR:  sscratch_f = (sscratch_f & ~`sscratch_MASK) | (csr_wdata & `sscratch_MASK);
        `sepc_ADDR:      sepc_f     = (sepc_f     & ~`sepc_MASK)     | (csr_wdata & `sepc_MASK);
        `scause_ADDR:    scause_f   = (scause_f   & ~`scause_MASK)   | (csr_wdata & `scause_MASK);
        `stval_ADDR:     stval_f    = (stval_f    & ~`stval_MASK)    | (csr_wdata & `stval_MASK);
        `satp_ADDR:      satp_f     = (satp_f     & ~`satp_MASK)     | (csr_wdata & `satp_MASK);
        default:         csrzero    = 32'b0;
    endcase
    end
end

always @(posedge clk) begin
    `ifdef DEBUG
        $display("==== CSR DEBUG ====");
        $display("csr_wen: %b, csr_wdata: %b, csr_waddr: %b", csr_wen, csr_wdata, csr_waddr);
        $display("CSR => PC: %h | priv: %h | mtvec: %h | mpec: %h | csr_rdata_EX: %h | csr_rdata_MEM: %h | csr_addr_EX: %h | csr_addr_MEM: %h", csr_trapPC, priv_c, mtvec_c, mepc_c, csr_rdata_EX, csr_rdata_MEM, csr_addr_EX, csr_addr_MEM);
    `endif

    if (rst) begin
        csrzero    <= 32'b0;
        priv_c     <= `PRIV_MACHINE;
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

        stvec_c    <= 32'b0;
        sscratch_c <= 32'b0;
        sepc_c     <= 32'b0;
        scause_c   <= 32'b0;
        stval_c    <= 32'b0;
        satp_c     <= 32'b0;
    end 
    else begin
        priv_c     <= priv_f;
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

        stvec_c    <= stvec_f;
        sscratch_c <= sscratch_f;
        sepc_c     <= sepc_f;
        scause_c   <= scause_f;
        stval_c    <= stval_f;
        satp_c     <= satp_f;
    end
end

reg [4:0] csr_trapID_temp;
wire trap_taken = (csr_trapID_temp != `EXCEPT_DO_NOTHING);

//trap handling
always @(*) begin
    priv_f     = priv_c;
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
        mip_f[`MIP_MSIP] = msip; 
        mip_f[`MIP_MTIP] = mtip; 
        mip_f[`MIP_MEIP] = meip;
    mcycle_f   = mcycle_c;
    if(mcycle_c == 32'hFFFFFFFF)
        mcycleh_f  = mcycleh_c + 1;
    else
        mcycleh_f  = mcycleh_c;
    stvec_f    = stvec_c;
    sscratch_f = sscratch_c;
    sepc_f     = sepc_c;
    scause_f   = scause_c;
    stval_f    = stval_c;
    satp_f     = satp_c;
    
    //interrupt
    csr_trapID_temp = csr_trapID;
    if (mstatus_c[`MSTATUS_MIE]) begin
        if (mie_c[`MIE_MSIE] && mip_c[`MIP_MSIP]) begin
            csr_trapID_temp = (1 << 4) + `MIP_MSIP;
        end else if (mie_c[`MIE_MTIE] && mip_c[`MIP_MTIP]) begin
            csr_trapID_temp = (1 << 4) + `MIP_MTIP;
        end else if (mie_c[`MIE_MEIE] && mip_c[`MIP_MEIP]) begin
            csr_trapID_temp = (1 << 4) + `MIP_MEIP;
        end
    end
    
    //exceptions
    if(csr_ecall) begin
        $display("ECALL => PC: %h | mtvec: %h | mpec: %h", csr_trapPC, mtvec_c, mepc_c);
    
        case(priv_c)
            `PRIV_USER: csr_trapID_temp     = `EXCEPT_ECALL_U;
            `PRIV_SUPER: csr_trapID_temp    = `EXCEPT_ECALL_S;
            `PRIV_MACHINE: csr_trapID_temp  = `EXCEPT_ECALL_M;
        endcase
    end
    if(trap_taken) begin
    `ifdef DEBUG_CSR
        $display("TRAP TAKEN at time %0t", $time);
        $display(" - Cause ID      : 0x%02h", csr_trapID_temp);
        $display(" - Faulting PC   : 0x%08h", csr_trapPC);
        $display(" - Faulting Inst : 0x%08h", faulting_inst);
        $display(" - Delegated     : %s", ((csr_trapID_temp[4] == 0 && medeleg_c[csr_trapID_temp]) ||
                                      (csr_trapID_temp[4] == 1 && mideleg_c[csr_trapID_temp[3:0]])) ? "Yes" : "No");
        $display(" - Privilege     : %0d", priv_c);
    `endif

        //Supervisor Mode
        if((csr_trapID_temp[4] == 0 && medeleg_c[csr_trapID_temp]        && priv_c != `PRIV_MACHINE) ||  // Exception delegation
           (csr_trapID_temp[4] == 1 && mideleg_c[csr_trapID_temp[3:0]]   && priv_c != `PRIV_MACHINE)) begin
            `ifdef DEBUG 
                $display("TRAP => PC: %h | stvec: %h | spec: %h", csr_trapPC, stvec_c, sepc_c);
            `endif
            mstatus_f[`MSTATUS_SPIE] = mstatus_c[`MSTATUS_SIE];
            mstatus_f[`MSTATUS_SPP]  = priv_c;
            mstatus_f[`MSTATUS_SIE]  = 1'b0;
            if(csr_trapID_temp[4] == 0)
                scause_f                 = {27'b0, csr_trapID_temp[4:0]};
            else
                scause_f                 = {1'b1, 26'b0, csr_trapID_temp[4:0]};
            sepc_f                   = csr_trapPC;
            priv_f                   = `PRIV_SUPER;

            case (csr_trapID_temp)  
                `EXCEPT_MISALIGNED_PC:    stval_f = csr_trapPC;              // faulting PC (instruction address misaligned)
                `EXCEPT_ACCESS_FAULT:     stval_f = csr_trapPC;              // faulting PC (instruction access fault)
                `EXCEPT_ILLEGAL_INST:     stval_f = faulting_inst;            // illegal instruction bits
                `EXCEPT_BREAKPOINT:       stval_f = csr_trapPC;              // faulting PC
                `EXCEPT_LOAD_MISALIGNED:  stval_f = 32'hxxxxxxxx;//faulting_load_addr;       // faulting load address (misaligned)
                `EXCEPT_LOAD_FAULT:       stval_f = 32'hxxxxxxxx;//faulting_load_addr;       // faulting load address (access fault)
                `EXCEPT_STORE_MISALIGNED: stval_f = 32'hxxxxxxxx;//faulting_store_addr;      // faulting store address (misaligned)
                `EXCEPT_STORE_FAULT:      stval_f = 32'hxxxxxxxx;//faulting_store_addr;      // faulting store address (access fault)
                `EXCEPT_ECALL_U:          stval_f = 32'h00000000;               // ECALL usually zero
                `EXCEPT_ECALL_S:          stval_f = 32'h00000000;               // ECALL usually zero
                `EXCEPT_ECALL_M:          stval_f = 32'h00000000;               // ECALL usually zero
                `EXCEPT_INST_PAGE_FAULT:  stval_f = csr_trapPC;              // faulting PC
                `EXCEPT_LOAD_PAGE_FAULT:  stval_f = faulting_va_DMEM;  //faulting_load_addr;       // faulting load address
                `EXCEPT_STORE_PAGE_FAULT: stval_f = faulting_va_DMEM;  //faulting_store_addr;      // faulting store address
                
                `INTER_MSIP:              stval_f = 32'h00000000;
                `INTER_MTIP:              stval_f = 32'h00000000;
                `INTER_MEIP:              stval_f = 32'h00000000;
                default:                  stval_f = 32'h00000000;              // default zero
            endcase
        end
        
        //Machine Mode
        else begin
            `ifdef DEBUG 
                $display("TRAP => PC: %h | mtvec: %h | mpec: %h", csr_trapPC, mtvec_c, mepc_c);
            `endif
            mstatus_f[`MSTATUS_MPIE] = mstatus_c[`MSTATUS_MIE];
            mstatus_f[`MSTATUS_MPP]  = priv_c;
            mstatus_f[`MSTATUS_MIE]  = 1'b0;
            if(csr_trapID_temp[4] == 0)
                mcause_f                 = {27'b0, csr_trapID_temp[4:0]};
            else
                mcause_f                 = {1'b1, 26'b0, csr_trapID_temp[4:0]};
            mepc_f                   = csr_trapPC;
            priv_f                   = `PRIV_MACHINE;

            case (csr_trapID_temp)  
                `EXCEPT_MISALIGNED_PC:    mtval_f = csr_trapPC;              // faulting PC (instruction address misaligned)
                `EXCEPT_ACCESS_FAULT:     mtval_f = csr_trapPC;              // faulting PC (instruction access fault)
                `EXCEPT_ILLEGAL_INST:     mtval_f = faulting_inst; //faulting_inst;            // illegal instruction bits
                `EXCEPT_BREAKPOINT:       mtval_f = csr_trapPC;              // faulting PC
                `EXCEPT_LOAD_MISALIGNED:  mtval_f = 32'hxxxxxxxx;//faulting_load_addr;       // faulting load address (misaligned)
                `EXCEPT_LOAD_FAULT:       mtval_f = 32'hxxxxxxxx;//faulting_load_addr;       // faulting load address (access fault)
                `EXCEPT_STORE_MISALIGNED: mtval_f = 32'hxxxxxxxx;//faulting_store_addr;      // faulting store address (misaligned)
                `EXCEPT_STORE_FAULT:      mtval_f = 32'hxxxxxxxx;//faulting_store_addr;      // faulting store address (access fault)
                `EXCEPT_ECALL_U:          mtval_f = 32'h00000000;               // ECALL usually zero
                `EXCEPT_ECALL_S:          mtval_f = 32'h00000000;               // ECALL usually zero
                `EXCEPT_ECALL_M:          mtval_f = 32'h00000000;               // ECALL usually zero
                `EXCEPT_INST_PAGE_FAULT:  mtval_f = csr_trapPC;              // faulting PC
                `EXCEPT_LOAD_PAGE_FAULT:  mtval_f = faulting_va_DMEM; //faulting_load_addr;       // faulting load address
                `EXCEPT_STORE_PAGE_FAULT: mtval_f = faulting_va_DMEM; //faulting_store_addr;      // faulting store address
                
                `INTER_MSIP:              mtval_f = 32'h00000000;
                `INTER_MTIP:              mtval_f = 32'h00000000;
                `INTER_MEIP:              mtval_f = 32'h00000000;
                default:                  mtval_f = 32'h00000000;              // default zero
            endcase
        end
    end

    //return
    else if(csr_mret) begin
        $display("MRET => PC: %h | mtvec: %h | mpec: %h | csr_rdata_EX: %h | csr_rdata_MEM: %h | csr_addr_EX: %h | csr_addr_MEM: %h", csr_trapPC, mtvec_c, mepc_c, csr_rdata_EX, csr_rdata_MEM, csr_addr_EX, csr_addr_MEM);
        priv_f                   = mstatus_c[`MSTATUS_MPP];
        mstatus_f[`MSTATUS_MIE]  = mstatus_c[`MSTATUS_MPIE];
        mstatus_f[`MSTATUS_MPIE] = 1'b1;
        mstatus_f[`MSTATUS_MPP]  = 2'b00;
    end
    else if(csr_sret) begin
        $display("SRET => PC: %h | stvec: %h | spec: %h | csr_rdata_EX: %h | csr_rdata_MEM: %h | csr_addr_EX: %h | csr_addr_MEM: %h", csr_trapPC, stvec_c, sepc_c, csr_rdata_EX, csr_rdata_MEM, csr_addr_EX, csr_addr_MEM);
        priv_f                   = {1'b0, mstatus_c[`MSTATUS_SPP]}; //SPP is only 1 bit
        mstatus_f[`MSTATUS_SIE]  = mstatus_c[`MSTATUS_SPIE];
        mstatus_f[`MSTATUS_SPIE] = 1'b1;
        mstatus_f[`MSTATUS_SPP]  = 1'b0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        csr_branch_signal  <= 1'b0;
        csr_branch_address <= 32'b0;
    end else begin
        csr_branch_signal  <= 1'b0;
        csr_branch_address <= 32'b0;

        if (csr_mret) begin
            csr_branch_signal  <= 1'b1;
            //CONSIDER CHANGING THIS IS ERROR PRONE!!!
            if (csr_addr_EX == `mepc_ADDR)
                csr_branch_address <= csr_rdata_EX;
            else if (csr_addr_MEM == `mepc_ADDR)
                csr_branch_address <= csr_rdata_MEM;
            else
                csr_branch_address <= mepc_c;
        end
        
        else if(csr_sret) begin
            csr_branch_signal  <= 1'b1;
            //CONSIDER CHANGING THIS IS ERROR PRONE!!!
            if (csr_addr_EX == `sepc_ADDR)
                csr_branch_address <= csr_rdata_EX;
            else if (csr_addr_MEM == `sepc_ADDR)
                csr_branch_address <= csr_rdata_MEM;
            else
                csr_branch_address <= sepc_c;
        end

        //exception
        else if (trap_taken && priv_c != `PRIV_MACHINE &&
        ((csr_trapID_temp[4] == 0 && medeleg_c[csr_trapID_temp]) ||
         (csr_trapID_temp[4] == 1 && mideleg_c[csr_trapID_temp[3:0]]))) begin
            csr_branch_signal  <= 1'b1;
            if (csr_addr_EX == `stvec_ADDR)
                csr_branch_address <= csr_rdata_EX;
            else if (csr_addr_MEM == `stvec_ADDR)
                csr_branch_address <= csr_rdata_MEM;
            else
                csr_branch_address <= stvec_c;
        end

        else if(trap_taken) begin
            csr_branch_signal  <= 1'b1;
        if (csr_addr_EX == `mtvec_ADDR)
            csr_branch_address <= csr_rdata_EX;
        else if (csr_addr_MEM == `mtvec_ADDR)
            csr_branch_address <= csr_rdata_MEM;
        else
            csr_branch_address <= mtvec_c;
        end
    end
end

assign priv_o = priv_c;
assign satp_o = satp_c;
assign sstatus_sum = mstatus_c[`MSTATUS_SUM];

endmodule
