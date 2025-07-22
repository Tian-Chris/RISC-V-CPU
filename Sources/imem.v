`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Chris Tian
// Module Name: imem
//////////////////////////////////////////////////////////////////////////////////

module imem #(parameter MEMSIZE = 50000000) (
    //IMEM
    input  wire        rst,
    input  wire [3:0]  hazard_signal,

    //DECODER
    input  wire [31:0] pc,
    output wire [31:0] IDinstruct_o,
    output wire [31:0] IDPC_o,
    output wire [4:0]  IDrs1_o,
    output wire [4:0]  IDrs2_o,
    output wire [4:0]  IDrd_o,
    output wire [31:0] IDinstCSR_o,
    output wire        invalid_inst,
    output wire        fence_active,
    output wire        access_is_load_ID,
    output wire        access_is_store_ID,
    output wire [31:0] faulting_inst,
    output wire        ecall,

    //DMEM
    input  wire        clk,
    input  wire        RW, // 1 = write, 0 = read
    input  wire [2:0]  funct3,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input wire WB_csr_reg_en,
    input wire [31:0] WB_csr_rresult,

    //MMU
    input  wire        sstatus_sum, //bit 18
    input  wire [31:0] csr_satp,       

    //IMEM MMU
    input  wire [1:0]  priv_IMEM, 
    input  wire [31:0] VPC_IMEM,       
    input  wire        validID,  
    input  wire        access_is_load_IMEM,
    input  wire        access_is_store_IMEM,
    input  wire        access_is_inst_IMEM,
    output wire        instr_fault_mmu_IMEM,
    output wire        load_fault_mmu_IMEM,
    output wire        store_fault_mmu_IMEM,
    output wire [31:0] faulting_va_IMEM,
    output wire        stall_IMEM,


    //DMEM MMU
    input  wire [1:0]  priv_DMEM,
    input  wire [31:0] VPC_DMEM, 
    input  wire        validMEM,  
    input  wire        access_is_load_DMEM,
    input  wire        access_is_store_DMEM,
    input  wire        access_is_inst_DMEM,
    output wire        instr_fault_mmu_DMEM,
    output wire        load_fault_mmu_DMEM,
    output wire        store_fault_mmu_DMEM,
    output wire [31:0] faulting_va_DMEM,
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

    reg [31:0] unified_mem [0:MEMSIZE];

    // Memory map regions
    localparam [31:0] RAM_BASE   = 32'h8000_0000;
    localparam [31:0] RAM_SIZE   = MEMSIZE;
    localparam [31:0] RAM_END    = RAM_BASE + RAM_SIZE;

    //MMU
    wire [31:0] PPC_IMEM;
    wire [31:0] PPC_DMEM;
    wire        virtual_mode_I = (csr_satp[31] && priv_IMEM != `PRIV_MACHINE);
    reg         LFM_resolved_IMEM;
    reg  [31:0] IMEM_word;
    wire [31:0] LFM_IMEM;
    wire        LFM_enable_IMEM;

    wire virtual_mode_D = (csr_satp[31] && priv_DMEM != `PRIV_MACHINE);
    reg         LFM_resolved_DMEM;
    reg  [31:0] DMEM_word;
    wire [31:0] LFM_DMEM;
    wire        LFM_enable_DMEM;
    
    wire [31:0] IMEM_Addr = virtual_mode_I ? PPC_IMEM : VPC_IMEM;
    wire [31:0] DMEM_Addr = virtual_mode_D ? PPC_DMEM : VPC_DMEM;
    wire [31:0] IMEM_ram = IMEM_Addr - RAM_BASE;
    wire [31:0] DMEM_ram = DMEM_Addr - RAM_BASE;
    wire [31:0] word_index = DMEM_ram[31:2];

    // ========
    //   IMEM
    // ========
    reg  [31:0] inst;
    reg  [4:0]  rd;
    reg  [4:0]  rs1;
    reg  [4:0]  rs2;
    reg  [31:0] IDPC;
    always @(posedge clk) begin
        if(rst || hazard_signal == `FLUSH_EARLY || hazard_signal == `FLUSH_ALL || fence_active) begin
            inst <= `INST_NOP;
            if(rst)
                IDPC <= 32'b0;
        end
        else if (hazard_signal != `STALL_EARLY && hazard_signal != `STALL_MMU) begin
            inst <= unified_mem[IMEM_ram[31:2]];
            IDPC <= pc;
        end
    end
    always @(*) begin
        rd   = inst[11:7];
        rs1  = inst[19:15];
        rs2  = inst[24:20];
    end
    assign IDPC_o = IDPC;

    decoder DEC (
        .clk(clk),
        .rst(rst),
        .hazard_signal(hazard_signal),
        .instruction(inst),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .IDinstruct(IDinstruct_o),
        .IDrs1(IDrs1_o),
        .IDrs2(IDrs2_o),
        .IDrd(IDrd_o),
        .IDinstCSR(IDinstCSR_o),
        .invalid_inst(invalid_inst),
        .fence_active(fence_active),
        .access_is_load_ID(access_is_load_ID),
        .access_is_store_ID(access_is_store_ID),
        .faulting_inst(faulting_inst),
        .ecall(ecall)
    );

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
    reg  [31:0] rdataclked;
    always @(posedge clk) begin
        if(hazard_signal != `STALL_MMU) begin
            if(DMEM_Addr < 32'h8000BF78 && DMEM_Addr >= 32'h8000BF74)
                $display("RW: %h, DMEM: %h, PC: %h, wdata: %h rdata: %h", RW, DMEM_Addr, pc, wdata, rdata);
        end
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
                        case(DMEM_ram[1:0])
                            2'b00: unified_mem[word_index][7:0]    <= wdata[7:0];
                            2'b01: unified_mem[word_index][15:8]   <= wdata[7:0];
                            2'b10: unified_mem[word_index][23:16]  <= wdata[7:0];
                            2'b11: unified_mem[word_index][31:24]  <= wdata[7:0];
                        endcase
                    end
                    3'b001: begin // sh
                        case(DMEM_ram[1:0])
                            2'b00: begin
                                unified_mem[word_index][7:0]   <= wdata[7:0];
                                unified_mem[word_index][15:8]  <= wdata[15:8];
                            end
                            2'b10: begin
                                unified_mem[word_index][23:16] <= wdata[7:0];
                                unified_mem[word_index][31:24] <= wdata[15:8];
                            end
                            2'b01: begin
                                unified_mem[word_index][15:8]  <= wdata[7:0];
                                unified_mem[word_index][23:16] <= wdata[15:8];
                            end
                        endcase
                    end
                    3'b010: begin // sw
                        unified_mem[word_index] <= wdata;
                    end
                    endcase
                end
            endcase
        end
    end

always @(*) begin
    if ((!RW) && (hazard_signal != `STALL_MMU)) begin
        case (DMEM_Addr)
            `UART_READ_ADDR:    rdata = {27'b0, rx_ready, 3'b0, tx_ready};
            `UART_WRITE_ADDR:   rdata = rx_data_output;
            `CLINT_MSIP_ADDR:   rdata = {31'b0, msip_reg};
            `CLINT_MTIME_ADDR:  rdata = mtime;
            `CLINT_MTIMEH_ADDR: rdata = mtimeh;

            //RAM
            default: begin
                case (funct3)
                    3'b000: begin // lb (sign-extend)
                        case(DMEM_ram[1:0])
                            2'b00: rdata = {{24{unified_mem[word_index][7]}}, unified_mem[word_index][7:0]};
                            2'b01: rdata = {{24{unified_mem[word_index][15]}}, unified_mem[word_index][15:8]};
                            2'b10: rdata = {{24{unified_mem[word_index][23]}}, unified_mem[word_index][23:16]};
                            2'b11: rdata = {{24{unified_mem[word_index][31]}}, unified_mem[word_index][31:24]};
                        endcase
                    end
                    3'b100: begin // lbu (zero-extend)
                        case(DMEM_ram[1:0])
                            2'b00: rdata = {24'b0, unified_mem[word_index][7:0]};
                            2'b01: rdata = {24'b0, unified_mem[word_index][15:8]};
                            2'b10: rdata = {24'b0, unified_mem[word_index][23:16]};
                            2'b11: rdata = {24'b0, unified_mem[word_index][31:24]};
                        endcase
                    end
                    3'b001: begin // lh (sign-extend)
                        case(DMEM_ram[1:0])
                            2'b00: rdata = {{16{unified_mem[word_index][15]}}, unified_mem[word_index][15:0]};
                            2'b10: rdata = {{16{unified_mem[word_index][31]}}, unified_mem[word_index][31:16]};
                            2'b01: rdata = {{16{unified_mem[word_index][31]}}, unified_mem[word_index][23:8]};
                        endcase   
                    end
                    3'b101: begin // lhu (zero-extend)
                        case(DMEM_ram[1:0])
                            2'b00: rdata = {16'b0, unified_mem[word_index][15:0]};
                            2'b10: rdata = {16'b0, unified_mem[word_index][31:16]};
                            2'b01: rdata = {16'b0, unified_mem[word_index][23:8]};
                        endcase
                    end
                    3'b010: begin // lw (32-bit word)
                        rdata = unified_mem[word_index];
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
    localparam [3:0] IDLE   = 4'b0000;
    localparam [3:0] LFMI   = 4'b0001;
    localparam [3:0] LFMD   = 4'b0101;
    localparam [3:0] STALL  = 4'b1001;
    reg        [3:0] STATE;
    reg        nextR;
    always @(posedge clk ) begin
        nextR <= 0;
        if(DMEM_ram == 32'h0000af98 || nextR) begin
            if(DMEM_ram == 32'h0000af98)
                nextR <= 1;
            $display("PC: %h, RW: %h, 8000af98:, %h", pc, RW, unified_mem[32'h0000af98 >> 2]);
            $display("wdata: %h, rdata: %h", wdata, rdata);
        end
        if(rst)
            STATE <= IDLE;
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
                IMEM_word <= unified_mem[(LFM_IMEM - RAM_BASE) >> 2];
                LFM_resolved_IMEM   <= 1;
                STATE   <= STALL;
            end
            LFMD: begin
                DMEM_word <= unified_mem[(LFM_DMEM - RAM_BASE) >> 2];
                LFM_resolved_DMEM   <= 1;
                STATE   <= STALL;
            end
            STALL:
                STATE <= IDLE;
            default:
                STATE <= IDLE;
        endcase
    end
    wire IMEM_busy;
    wire DMEM_busy;
    wire MMU_hand_shake = IMEM_busy || DMEM_busy;
    MMU_unit IMEM_MMU (
        .clk(clk),
        .rst(rst),
        .hazard_signal(hazard_signal),
        .VPC(VPC_IMEM),
        .csr_satp(csr_satp),    
        .priv(priv_IMEM),    
        .valid(validID),
        .LFM_resolved(LFM_resolved_IMEM),
        .LFM_word(IMEM_word),
        .sstatus_sum(sstatus_sum), //bit 18
        .access_is_load(access_is_load_IMEM),
        .access_is_store(access_is_store_IMEM),
        .access_is_inst(access_is_inst_IMEM),
        .instr_fault_mmu(instr_fault_mmu_IMEM),
        .load_fault_mmu(load_fault_mmu_IMEM), 
        .store_fault_mmu(store_fault_mmu_IMEM),
        .faulting_va(faulting_va_IMEM),
        .stall(stall_IMEM),
        .MMU_busy(IMEM_busy),
        .LFM(LFM_IMEM),
        .LFM_enable(LFM_enable_IMEM),
        .PC(PPC_IMEM),
        .MMU_hand_shake(MMU_hand_shake)
    );

    MMU_unit DMEM_MMU (
        .clk(clk),
        .rst(rst),
        .hazard_signal(hazard_signal),
        .VPC(VPC_DMEM),
        .csr_satp(csr_satp),    
        .priv(priv_DMEM),   
        .valid(validMEM), 
        .LFM_resolved(LFM_resolved_DMEM),
        .LFM_word(DMEM_word),
        .sstatus_sum(sstatus_sum), //bit 18
        .access_is_load(access_is_load_DMEM),
        .access_is_store(access_is_store_DMEM),
        .access_is_inst(access_is_inst_DMEM),
        .instr_fault_mmu(instr_fault_mmu_DMEM),
        .load_fault_mmu(load_fault_mmu_DMEM), 
        .store_fault_mmu(store_fault_mmu_DMEM),
        .faulting_va(faulting_va_DMEM),
        .stall(stall_DMEM),
        .MMU_busy(DMEM_busy),
        .LFM(LFM_DMEM),
        .LFM_enable(LFM_enable_DMEM),
        .PC(PPC_DMEM),
        .MMU_hand_shake(MMU_hand_shake)
    );

endmodule
