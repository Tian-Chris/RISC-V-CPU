`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Chris Tian
// Module Name: imem
//////////////////////////////////////////////////////////////////////////////////

module imem #(parameter MEMSIZE = 70000) (
    //IMEM
    input  wire        rst,
    output reg  [31:0] inst,
    output reg  [4:0]  rd,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2,
    input  wire [3:0]  hazard_signal,

    //DMEM
    input  wire        clk,
    input  wire        RW, // 1 = write, 0 = read
    input  wire [2:0]  funct3,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,

    //MMU
    input  wire        sstatus_sum, //bit 18
    input  wire [31:0] csr_satp,       

    //IMEM    
    input  wire [1:0]  priv_IMEM, 
    input  wire [31:0] VPC_IMEM,         
    input  wire        access_is_load_IMEM,
    input  wire        access_is_store_IMEM,
    input  wire        access_is_inst_IMEM,
    output wire        instr_fault_mmu_IMEM,
    output wire        load_fault_mmu_IMEM,
    output wire        store_fault_mmu_IMEM,
    output wire [31:0] faulting_va_IMEM,
    output wire [31:0] PPC_IMEM,
    output wire        stall_IMEM,


    //DMEM
    input  wire [1:0]  priv_DMEM,
    input  wire [31:0] VPC_DMEM, 
    input  wire        access_is_load_DMEM,
    input  wire        access_is_store_DMEM,
    input  wire        access_is_inst_DMEM,
    output wire        instr_fault_mmu_DMEM,
    output wire        load_fault_mmu_DMEM,
    output wire        store_fault_mmu_DMEM,
    output wire [31:0] faulting_va_DMEM,
    output wire [31:0] PPC_DMEM,
    output wire        stall_DMEM,

    //CLINT
    output wire        msip,   
    output wire        mtip,

    //uart
    output wire        meip

    );
    `include "csr_defs.v"
    `ifdef DEBUG_ALL
        `define DEBUG_IMEM
    `endif
    reg [7:0] unified_mem [0:MEMSIZE];
    wire virtual_mode_I = (csr_satp[31] && priv_IMEM != `PRIV_MACHINE);
    wire virtual_mode_D = (csr_satp[31] && priv_DMEM != `PRIV_MACHINE);

    //MMU
    reg         LFM_resolved_IMEM;
    reg [7:0]   b1_IMEM, b2_IMEM, b3_IMEM, b4_IMEM;
    wire [31:0] LFM_IMEM;
    wire        LFM_enable_IMEM;

    reg         LFM_resolved_DMEM;
    reg [7:0]   b1_DMEM, b2_DMEM, b3_DMEM, b4_DMEM;
    wire [31:0] LFM_DMEM;
    wire        LFM_enable_DMEM;
    
    wire [31:0] IMEM_Addr = virtual_mode_I ? PPC_IMEM : VPC_IMEM;
    wire [31:0] DMEM_Addr = virtual_mode_D ? PPC_DMEM : VPC_DMEM;
    
    // ========
    //   IMEM
    // ========
    always @(*) begin

        `ifdef ENDIAN_BIG
            if(hazard_signal == `STALL_MMU)
                inst = `INST_NOP;
            else
                inst = {unified_mem[IMEM_Addr], unified_mem[IMEM_Addr + 1], unified_mem[IMEM_Addr + 2], unified_mem[IMEM_Addr + 3]};
        `else // default to little endian
            if(hazard_signal == `STALL_MMU)
                inst = `INST_NOP;
            else
                inst = {unified_mem[IMEM_Addr + 3], unified_mem[IMEM_Addr + 2], unified_mem[IMEM_Addr + 1], unified_mem[IMEM_Addr]};
        `endif

        rd  = inst[11:7];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
    end

    // ========
    //   UART
    // ========
    //uart
    reg         uart_fifo_write_en;
    reg [7:0]   uart_fifo_data;
    reg         cpu_read;
    wire        rx_line;
    wire        tx_line;
    wire        rx_ready;
    wire        tx_ready;
    wire [31:0]  rx_data_output;


    //Timer
    reg [31:0] mtime;
    reg [31:0] mtimeh;
    reg [31:0] mtimecmp;
    reg [31:0] mtimecmph;
    reg        msip_reg;

    always @(posedge clk) begin
        if (rst)
            mtime  <= 32'b0;
        else if(mtime != 32'hFFFFFFFF)
            mtime  <= mtime + 1;
        else begin
            mtime  <= 0;
            mtimeh <= mtimeh + 1;
        end
    end

    assign msip = msip_reg;
    assign mtip = ({mtimeh, mtime} >= {mtimecmph, mtimecmp});
    assign meip = rx_ready;
    
    // ========
    //   DMEM
    // ========
    reg [31:0] rdataclked;
    always @(posedge clk) begin
        `ifdef DEBUG_IMEM
            $display("===========  IMEM  ===========");
            $display("[MEM] RW: %b, addr=%h, data=%h, rdata=%h", RW, DMEM_Addr, wdata, rdata);
            $display("[MEM] 0 %h", unified_mem[32'h00000000]);
            $display("[MEM] aec8: %h%h%h%h, aecc: %h%h%h%h af54: %h%h%h%h", unified_mem[32'h0000aecB],unified_mem[32'h0000aeca],unified_mem[32'h0000aec9],unified_mem[32'h0000aec8], unified_mem[32'h0000aecf],
            unified_mem[32'h0000aece],unified_mem[32'h0000aecd],unified_mem[32'h0000aecc], unified_mem[32'h0000af57], unified_mem[32'h0000af56], unified_mem[32'h0000af55], unified_mem[32'h0000af54]);
        `endif
        uart_fifo_write_en <= 0;
        rdataclked <= rdata;
        if(RW && (hazard_signal != `STALL_MMU)) begin
            case(DMEM_Addr)

                `UART_WRITE_ADDR: begin
                    uart_fifo_write_en <= 1;
                    uart_fifo_data     <= wdata[7:0];
                end
                `UART_READ_ADDR:  begin end//does nothing cannot write to this addr
                `CLINT_MSIP_ADDR:      msip_reg        <= wdata[0];
                `CLINT_MTIMECMP_ADDR:  mtimecmp[31:0]  <= wdata;
                `CLINT_MTIMECMPH_ADDR: mtimecmph[31:0] <= wdata;
                `CLINT_MTIMEH_ADDR:    mtimeh          <= wdata;

                default: begin
                    case(funct3)
                    3'b000: begin // sb
                        unified_mem[DMEM_Addr]       <= wdata[7:0];
                    end
                    3'b001: begin // sh 
                        unified_mem[DMEM_Addr]       <= wdata[7:0];
                        unified_mem[DMEM_Addr + 1]   <= wdata[15:8];
                    end
                    3'b010: begin // sw 
                        unified_mem[DMEM_Addr]       <= wdata[7:0];
                        unified_mem[DMEM_Addr + 1]   <= wdata[15:8];
                        unified_mem[DMEM_Addr + 2]   <= wdata[23:16];
                        unified_mem[DMEM_Addr + 3]   <= wdata[31:24];
                    end
                    default:;
                    endcase
                end
            endcase
        end
    end
always @(*) begin
    `ifdef DEBUG_IMEM
        $display("hazard_signal: %b, funct3: %b", hazard_signal, funct3);
    `endif
    if ((!RW) && (hazard_signal != `STALL_MMU)) begin
        case (DMEM_Addr)
            `UART_READ_ADDR:    rdata = {27'b0, rx_ready, 3'b0, tx_ready};
            `UART_WRITE_ADDR:   rdata = rx_data_output;
            `CLINT_MSIP_ADDR:   rdata = {31'b0, msip_reg};
            `CLINT_MTIME_ADDR:  rdata = mtime;
            `CLINT_MTIMEH_ADDR: rdata = mtimeh;

            default: begin
                case (funct3)
                    3'b000: begin // lb (sign-extend)
                        rdata = {{24{unified_mem[DMEM_Addr][7]}}, unified_mem[DMEM_Addr]};
                    end
                    3'b100: begin // lbu (zero-extend)
                        rdata = {24'b0, unified_mem[DMEM_Addr]};
                    end
                    3'b001: begin // lh (sign-extend)
                        rdata = {{16{unified_mem[DMEM_Addr + 1][7]}}, 
                                  unified_mem[DMEM_Addr + 1], 
                                  unified_mem[DMEM_Addr]};
                    end
                    3'b101: begin // lhu (zero-extend)
                        rdata = {16'b0, 
                                 unified_mem[DMEM_Addr + 1], 
                                 unified_mem[DMEM_Addr]};
                    end
                    3'b010: begin // lw (32-bit word)
                        rdata = {unified_mem[DMEM_Addr + 3], 
                                 unified_mem[DMEM_Addr + 2], 
                                 unified_mem[DMEM_Addr + 1], 
                                 unified_mem[DMEM_Addr]};
                    end
                    default: rdata = 32'b0;
                endcase
            end
        endcase
    end
end
        
    always @(posedge clk) begin
        if (rst) begin
            cpu_read <= 0;
        end else begin
            cpu_read <= 0;
            if (!RW && DMEM_Addr == `UART_WRITE_ADDR && hazard_signal != `STALL_MMU)
                cpu_read <= 1;
        end
    end
        
        
    uart_unit #(.DEPTH(32)) uart (
        .clk(clk),
        .rst(rst),
        .uart_fifo_write_en(uart_fifo_write_en),
        .cpu_read(cpu_read),
        .rx_line(rx_line),
        .tx_line(tx_line),
        .rx_ready(rx_ready),
        .tx_ready(tx_ready),
        .uart_fifo_data(uart_fifo_data),
        .rx_data_output(rx_data_output)
    );

    //FSM
    wire [3:0] IDLE   = 4'b0000;
    wire [3:0] LFMI   = 4'b0001;
    wire [3:0] LFMI2  = 4'b0010;
    wire [3:0] LFMI3  = 4'b0011;
    wire [3:0] LFMI4  = 4'b0100;
    wire [3:0] LFMD   = 4'b0101;
    wire [3:0] LFMD2  = 4'b0110;
    wire [3:0] LFMD3  = 4'b0111;
    wire [3:0] LFMD4  = 4'b1000;
    wire [3:0] STALL  = 4'b1001;
    reg  [3:0] STATE;
    always @(posedge clk ) begin
    `ifdef DEBUG_IMEM
        $display("IMEM => State: %h, virtual_mode_I: %h, virtual_mode_D: %h, LFM_enable_IMEM: %h, LFM_enable_DMEM: %h", STATE, virtual_mode_I, virtual_mode_D, LFM_enable_IMEM, LFM_enable_DMEM);
    `endif
        case(STATE)
            IDLE: begin
                LFM_resolved_IMEM <= 0;
                LFM_resolved_DMEM <= 0;
                if(LFM_enable_IMEM)
                    STATE <= LFMI;
                else if(LFM_enable_DMEM)
                    STATE <= LFMD;
            end
            LFMI: begin
                b1_IMEM <= unified_mem[LFM_IMEM];
                STATE   <= LFMI2;
            end
            LFMI2: begin
                b2_IMEM <= unified_mem[LFM_IMEM + 1];
                STATE   <= LFMI3;
            end
            LFMI3: begin
                b3_IMEM <= unified_mem[LFM_IMEM + 2];
                STATE   <= LFMI4;
            end
            LFMI4: begin
                b4_IMEM             <= unified_mem[LFM_IMEM + 3];
                LFM_resolved_IMEM   <= 1;
                STATE               <= STALL;
            end
            LFMD: begin
                b1_DMEM <= unified_mem[LFM_DMEM];
                STATE   <= LFMD2;
            end
            LFMD2: begin
                b2_DMEM <= unified_mem[LFM_DMEM + 1];
                STATE   <= LFMD3;
            end
            LFMD3: begin
                b3_DMEM <= unified_mem[LFM_DMEM + 2];
                STATE   <= LFMD4;
            end
            LFMD4: begin
                b4_DMEM       <= unified_mem[LFM_DMEM + 3];
                LFM_resolved_DMEM   <= 1;
                STATE               <= STALL;
            end
            STALL:
                STATE <= IDLE;
            default:
                STATE <= IDLE;
        endcase
    end

    MMU_unit IMEM_MMU (
        .clk(clk),
        .rst(rst),
        .VPC(VPC_IMEM),
        .csr_satp(csr_satp),    
        .priv(priv_IMEM),    
        .LFM_resolved(LFM_resolved_IMEM),
        .b1(b1_IMEM),
        .b2(b2_IMEM),
        .b3(b3_IMEM),
        .b4(b4_IMEM),
        .sstatus_sum(sstatus_sum), //bit 18
        .access_is_load(access_is_load_IMEM),
        .access_is_store(access_is_store_IMEM),
        .access_is_inst(access_is_inst_IMEM),
        .instr_fault_mmu(instr_fault_mmu_IMEM),
        .load_fault_mmu(load_fault_mmu_IMEM), 
        .store_fault_mmu(store_fault_mmu_IMEM),
        .faulting_va(faulting_va_IMEM),
        .stall(stall_IMEM),
        .LFM(LFM_IMEM),
        .LFM_enable(LFM_enable_IMEM),
        .PC(PPC_IMEM),
        .hazard_signal(hazard_signal)
    );

    MMU_unit DMEM_MMU (
        .clk(clk),
        .rst(rst),
        .VPC(VPC_DMEM),
        .csr_satp(csr_satp),    
        .priv(priv_DMEM),    
        .LFM_resolved(LFM_resolved_DMEM),
        .b1(b1_DMEM),
        .b2(b2_DMEM),
        .b3(b3_DMEM),
        .b4(b4_DMEM),
        .sstatus_sum(sstatus_sum), //bit 18
        .access_is_load(access_is_load_DMEM),
        .access_is_store(access_is_store_DMEM),
        .access_is_inst(access_is_inst_DMEM),
        .instr_fault_mmu(instr_fault_mmu_DMEM),
        .load_fault_mmu(load_fault_mmu_DMEM), 
        .store_fault_mmu(store_fault_mmu_DMEM),
        .faulting_va(faulting_va_DMEM),
        .stall(stall_DMEM),
        .LFM(LFM_DMEM),
        .LFM_enable(LFM_enable_DMEM),
        .PC(PPC_DMEM),
        .hazard_signal(hazard_signal)
    );

endmodule
