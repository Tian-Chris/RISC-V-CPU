`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/21/2025 12:00:38 PM
// Design Name: 
// Module Name: dmem
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


module dmem(
    input  wire        clk,
    input  wire        rst,
    input  wire        RW, // 1 = write, 0 = read
    input  wire [2:0]  funct3,
    input  wire [31:0] address,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output wire        exception,
    output wire [3:0]  exception_code,

    //MMU
    input  wire        sstatus_sum, //bit 18
    input  wire [31:0] csr_satp,    
    input  wire [1:0]  priv,    

    //IMEM    
    input  wire [31:0] VPC_IMEM,         
    input  wire        access_is_load_IMEM,
    input  wire        access_is_store_IMEM,
    input  wire        access_is_inst_IMEM,
    output wire        instr_fault_mmu_IMEM,
    output wire        load_fault_mmu_IMEM,
    output wire        store_fault_mmu_IMEM,
    output wire [31:0] faulting_va_IMEM,
    output reg  [31:0] PC_IMEM,

    //DMEM
    input  wire [31:0] VPC_DMEM, 
    input  wire        access_is_load_DMEM,
    input  wire        access_is_store_DMEM,
    input  wire        access_is_inst_DMEM,
    output wire        instr_fault_mmu_DMEM,
    output wire        load_fault_mmu_DMEM,
    output wire        store_fault_mmu_DMEM,
    output wire [31:0] faulting_va_DMEM,
    output reg  [31:0] PC_DMEM,

    //CLINT
    output wire        msip,   
    output wire        mtip,

    //uart
    output wire        meip
    );
    
    `include "csr_defs.v"

    reg [7:0] dmem [127:0];
    assign exception = ((address[0] || address[1]) && funct3 == 3'b010 ) || //word
                       ((address[0]) && funct3 == 3'b001 ); //haldword

    assign exception_code = RW; // read wrong 0, write wrong 1

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
    
    always @(posedge clk) begin
        uart_fifo_write_en <= 0;
        if(RW) begin
            case(address)

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
                        dmem[address]       <= wdata[7:0];
                    end
                    3'b001: begin // sh 
                        dmem[address]       <= wdata[7:0];
                        dmem[address + 1]   <= wdata[7:0];
                    end
                    3'b010: begin // sw 
                        dmem[address]       <= wdata[7:0];
                        dmem[address + 1]   <= wdata[7:0];
                        dmem[address + 2]   <= wdata[7:0];
                        dmem[address + 3]   <= wdata[7:0];
                    end
                    endcase
                end
            endcase
        end
    end

    always @(*) begin
        if(!RW) begin
            case(address)
                `UART_READ_ADDR:    rdata = {27'b0, rx_ready, 3'b0, tx_ready};
                `UART_WRITE_ADDR:   rdata = rx_data_output;
                `CLINT_MSIP_ADDR:   rdata = {31'b0, msip_reg};
                `CLINT_MTIME_ADDR:  rdata = mtime;
                `CLINT_MTIMEH_ADDR: rdata = mtimeh;
                default: begin
                    case(funct3)
                    3'b000: begin // lb  sign-extend
                        rdata = {{24{dmem[address[7]]}},   dmem[address]};
                    end
                    3'b100: begin // lbu zero-extend
                        rdata = {{24{1'b0}},   dmem[address]};
                    end
                    3'b001: begin // lh sign-extend
                        rdata = {{16{dmem[address + 1][7]}}, dmem[address], dmem[address + 1]};
                    end
                    3'b101: begin // lhu zero-extend
                        rdata = {{16{1'b0}}, dmem[address], dmem[address + 1]};
                    end
                    3'b010: begin // lw
                        rdata = {dmem[address], dmem[address + 1], dmem[address + 2], dmem[address + 3]};
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
            if (!RW && address == `UART_WRITE_ADDR)
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

// =========
//    MMU
// =========
wire [31:0] base_addr_IMEM = {csr_satp[21:0], 12'b0};
wire [9:0]  vpn1_IMEM = VPC_IMEM[31:22];
wire [9:0]  vpn0_IMEM = VPC_IMEM[21:12];

//level 1
reg  [31:0] l1_addr_IMEM;      
reg  [31:0] l1_pte_IMEM;      

//level 0
reg  [31:0] l0_addr_IMEM;  
reg  [31:0] l0_pte_IMEM;

//exception_IMEM
reg         exception_IMEM;

always @(*) begin
    exception_IMEM = 1'b0;
    if (csr_satp[31:30] == 2'b01) begin
        l1_addr_IMEM = base_addr_IMEM + (vpn1_IMEM << 2);
        l1_pte_IMEM = {dmem[l1_addr_IMEM], dmem[l1_addr_IMEM + 1], dmem[l1_addr_IMEM + 2], dmem[l1_addr_IMEM + 3]};

        //check priv
        if(l1_pte_IMEM[4] == 0 && priv == `PRIV_USER) begin
            exception_IMEM = 1;
            PC_IMEM = 32'hDEAD_BEEF;
        end else if(l1_pte_IMEM[4] == 1 && priv == `PRIV_SUPER && sstatus_sum == 0) begin
            exception_IMEM = 1;
            PC_IMEM = 32'hDEAD_BEEF;
        end

        // check l1 validity
        else if (l1_pte_IMEM[0] == 0) begin
            exception_IMEM = 1'b1;
            PC_IMEM = 32'hDEAD_BEEF;
        end 

        else if ((l1_pte_IMEM[1] == 0) && (l1_pte_IMEM[2] == 0)) begin //if neither read and write or exec its not a superleaf
            l0_addr_IMEM = {l1_pte_IMEM[31:10], 12'b0} + (vpn0_IMEM << 2);
            l0_pte_IMEM = {dmem[l0_addr_IMEM], dmem[l0_addr_IMEM + 1], dmem[l0_addr_IMEM + 2], dmem[l0_addr_IMEM + 3]};

            //check priv
            if(l0_pte_IMEM[4] == 0 && priv == `PRIV_USER) begin
                exception_IMEM = 1;
                PC_IMEM = 32'hDEAD_BEEF;
            end else if(l0_pte_IMEM[4] == 1 && priv == `PRIV_SUPER && sstatus_sum == 0) begin
                exception_IMEM = 1;
                PC_IMEM = 32'hDEAD_BEEF;
            end

            //check l0 valididty
            if (l0_pte_IMEM[0] == 0) begin
                exception_IMEM = 1'b1;
                PC_IMEM = 32'hDEAD_BEEF;
            end 
            else if ( (access_is_inst_IMEM && (l0_pte_IMEM[3] == 0)) ||
                (access_is_load_IMEM  && (l0_pte_IMEM[1] == 0))       ||
                (access_is_store_IMEM && (l0_pte_IMEM[2] == 0 || l0_pte_IMEM[7] == 0)) ) begin //checks dirty bit as well
                // if dirty bit = 0 except -> trap -> os -> sets db to 1
                exception_IMEM = 1'b1;
                PC_IMEM = 32'hDEAD_BEEF;
            end 
            else begin
                PC_IMEM = {l0_pte_IMEM[31:12], VPC_IMEM[11:0]};
            end
        end 

        else begin
            if ( (access_is_inst_IMEM && (l1_pte_IMEM[3] == 0)) ||
                (access_is_load_IMEM  && (l1_pte_IMEM[1] == 0))  ||
                (access_is_store_IMEM && (l1_pte_IMEM[2] == 0 || l1_pte_IMEM[7] == 0)) ) begin //checks dirty bit as well
                // if dirty bit = 0 except -> trap -> os -> sets db to 1
                exception_IMEM = 1'b1;
                PC_IMEM = 32'hDEAD_BEEF;
            end else begin
                PC_IMEM = {l1_pte_IMEM[31:10], VPC_IMEM[21:0]};
            end 
        end
    end 
    else
        PC_IMEM = VPC_IMEM;
end

assign faulting_va_IMEM     = VPC_IMEM;
assign instr_fault_mmu_IMEM = exception_IMEM ? (access_is_inst_IMEM ? 1'b1 : 1'b0) : 1'b0;
assign load_fault_mmu_IMEM  = exception_IMEM ? (access_is_load_IMEM  ? 1'b1 : 1'b0) : 1'b0;
assign store_fault_mmu_IMEM = exception_IMEM ? (access_is_store_IMEM ? 1'b1 : 1'b0) : 1'b0;

//DMEM
wire [31:0] base_addr_DMEM = {csr_satp[21:0], 12'b0};
wire [9:0]  vpn1_DMEM = VPC_DMEM[31:22];
wire [9:0]  vpn0_DMEM = VPC_DMEM[21:12];

//level 1
reg  [31:0] l1_addr_DMEM;      
reg  [31:0] l1_pte_DMEM;      

//level 0
reg  [31:0] l0_addr_DMEM;  
reg  [31:0] l0_pte_DMEM;

//exception_DMEM
reg         exception_DMEM;

always @(*) begin
    exception_DMEM = 1'b0;
    if (csr_satp[31:30] == 2'b01) begin
        l1_addr_DMEM = base_addr_DMEM + (vpn1_DMEM << 2);
        l1_pte_DMEM = {dmem[l1_addr_DMEM], dmem[l1_addr_DMEM + 1], dmem[l1_addr_DMEM + 1], dmem[l1_addr_DMEM + 1]};

        //check priv
        if(l1_pte_DMEM[4] == 0 && priv == `PRIV_USER) begin
            exception_DMEM = 1;
            PC_DMEM = 32'hDEAD_BEEF;
        end else if(l1_pte_DMEM[4] == 1 && priv == `PRIV_SUPER && sstatus_sum == 0) begin
            exception_DMEM = 1;
            PC_DMEM = 32'hDEAD_BEEF;
        end

        // check l1 validity
        else if (l1_pte_DMEM[0] == 0) begin
            exception_DMEM = 1'b1;
            PC_DMEM = 32'hDEAD_BEEF;
        end 

        else if ((l1_pte_DMEM[1] == 0) && (l1_pte_DMEM[2] == 0)) begin //if neither read and write or exec its not a superleaf
            l0_addr_DMEM = {l1_pte_DMEM[31:10], 12'b0} + (vpn0_DMEM << 2);
            l0_pte_DMEM = {dmem[l0_addr_DMEM], dmem[l0_addr_DMEM + 1], dmem[l0_addr_DMEM + 2], dmem[l0_addr_DMEM + 3]};

            //check priv
            if(l0_pte_DMEM[4] == 0 && priv == `PRIV_USER) begin
                exception_DMEM = 1;
                PC_DMEM = 32'hDEAD_BEEF;
            end else if(l0_pte_DMEM[4] == 1 && priv == `PRIV_SUPER && sstatus_sum == 0) begin
                exception_DMEM = 1;
                PC_DMEM = 32'hDEAD_BEEF;
            end

            //check l0 valididty
            if (l0_pte_DMEM[0] == 0) begin
                exception_DMEM = 1'b1;
                PC_DMEM = 32'hDEAD_BEEF;
            end 
            else if ( (access_is_inst_DMEM && (l0_pte_DMEM[3] == 0)) ||
                (access_is_load_DMEM  && (l0_pte_DMEM[1] == 0))       ||
                (access_is_store_DMEM && (l0_pte_DMEM[2] == 0 || l0_pte_DMEM[7] == 0)) ) begin //checks dirty bit as well
                // if dirty bit = 0 except -> trap -> os -> sets db to 1
                exception_DMEM = 1'b1;
                PC_DMEM = 32'hDEAD_BEEF;
            end 
            else begin
                PC_DMEM = {l0_pte_DMEM[31:12], VPC_DMEM[11:0]};
            end
        end 

        else begin
            if ( (access_is_inst_DMEM && (l1_pte_DMEM[3] == 0)) ||
                (access_is_load_DMEM  && (l1_pte_DMEM[1] == 0))  ||
                (access_is_store_DMEM && (l1_pte_DMEM[2] == 0 || l1_pte_DMEM[7] == 0)) ) begin //checks dirty bit as well
                // if dirty bit = 0 except -> trap -> os -> sets db to 1
                exception_DMEM = 1'b1;
                PC_DMEM = 32'hDEAD_BEEF;
            end else begin
                PC_DMEM = {l1_pte_DMEM[31:10], VPC_DMEM[21:0]};
            end 
        end
    end 
    else
        PC_DMEM = VPC_DMEM;
end

//exception_DMEM
assign faulting_va_DMEM     = VPC_DMEM;
assign instr_fault_mmu_DMEM = exception_DMEM ? (access_is_inst_DMEM ? 1'b1 : 1'b0) : 1'b0;
assign load_fault_mmu_DMEM  = exception_DMEM ? (access_is_load_DMEM  ? 1'b1 : 1'b0) : 1'b0;
assign store_fault_mmu_DMEM = exception_DMEM ? (access_is_store_DMEM ? 1'b1 : 1'b0) : 1'b0;

endmodule
