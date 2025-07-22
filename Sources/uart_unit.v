`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2025 10:21:47 AM
// Design Name: 
// Module Name: uart_unit
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
module uart_unit #( parameter DEPTH = 32 ) (
    input  wire       clk,
    input  wire       rst,
    input  wire       uart_fifo_write_en,
    input  wire [7:0] uart_fifo_data,
    input  wire       cpu_read,
    input  wire       rx_line,
    output reg        tx_line,
    output reg        rx_ready,
    output wire       tx_ready,
    output reg [31:0] rx_data_output
);
    parameter   CLOCK_FREQ = 50_000_000;   // 50 MHz
    parameter   BAUD_RATE  = 115200;
    localparam  BAUD_TICKS = CLOCK_FREQ / BAUD_RATE;
    wire        write_fifo_empty;
    wire         write_fifo_full;
    reg         write_fifo_read_en;
    wire        write_fifo_out_valid;
    wire [7:0]  write_fifo_output;
    reg  [7:0]  write_fifo_output_storage;
    assign tx_ready = !write_fifo_full;

    reg         read_fifo_write_en;
    reg  [7:0]  read_fifo_data;
    reg         read_fifo_read_en;
    wire        read_fifo_out_valid;
    wire [7:0]  read_fifo_output;
    wire        read_fifo_empty;
    wire        read_fifo_full;

    reg  [9:0]  shift_reg;   // {stop_bit, data[7:0], start_bit}
    reg  [4:0]  bit_idx;
    reg  [15:0] baud_cnt;
    reg  [2:0]  wait_counter;

    reg  [15:0] read_baud_cnt;
    reg  [4:0]  read_bit;
    reg  [9:0]  read_storage;

    wire [2:0] WRITE_IDLE  = 2'b00;
    wire [2:0] WRITE_WAIT  = 2'b01;
    wire [2:0] WRITE_EXEC  = 2'b10;

    wire [3:0] READ_IDLE   = 3'b000;
    wire [3:0] READ_WAIT   = 3'b001;
    wire [3:0] READ_DETECT = 3'b010;
    wire [3:0] READ_STOP   = 3'b011;
    wire [3:0] READ_WRITE  = 3'b100;

    reg  [1:0] WRITE_state, WRITE_next_state;
    reg  [2:0] READ_state, READ_next_state;

    fifo_unit #(
        .DEPTH(DEPTH),
        .WIDTH(8)
    ) tx_fifo (
        .clk(clk),
        .rst(rst),
        .fifo_write_en(uart_fifo_write_en),
        .fifo_write_data(uart_fifo_data),
        .fifo_read_en(write_fifo_read_en),
        .fifo_full(write_fifo_full),
        .fifo_empty(write_fifo_empty),
        .fifo_out_valid(write_fifo_out_valid),
        .fifo_output(write_fifo_output)
    );

    fifo_unit #(
        .DEPTH(DEPTH),
        .WIDTH(8)
    ) rx_fifo (
        .clk(clk),
        .rst(rst),
        .fifo_write_en(read_fifo_write_en),
        .fifo_write_data(read_fifo_data),
        .fifo_read_en(read_fifo_read_en),
        .fifo_full(read_fifo_full),
        .fifo_empty(read_fifo_empty),
        .fifo_out_valid(read_fifo_out_valid),
        .fifo_output(read_fifo_output)
    );


    //FSM WRITE
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            WRITE_state <= WRITE_IDLE;
            write_fifo_read_en <= 0;
            wait_counter <= 0;
            tx_line <= 1;
            shift_reg <= 10'b1111111111;
            bit_idx <= 0;
            baud_cnt <= 0;
        end else begin
            WRITE_state <= WRITE_next_state;
            case(WRITE_state)
                WRITE_IDLE: begin
                    if(!write_fifo_empty)
                        write_fifo_read_en <= 1;
                    else
                        write_fifo_read_en <= 0;
                    wait_counter <= 0;
                    tx_line  <= 1;
                    bit_idx  <= 0;
                    baud_cnt <= 0;
                end
                WRITE_WAIT: begin
                    if(write_fifo_out_valid) begin
                        write_fifo_read_en <= 0;
                        write_fifo_output_storage <= write_fifo_output;
                    end
                    wait_counter <= wait_counter + 1;
                end
                WRITE_EXEC: begin
                    shift_reg <= {1'b1, write_fifo_output_storage, 1'b0};
                    baud_cnt <= baud_cnt + 1;
                    if (baud_cnt == BAUD_TICKS - 1) begin
                        baud_cnt <= 0;
                        tx_line <= shift_reg[bit_idx];
                        bit_idx <= bit_idx + 1;
                        if (bit_idx == 10)
                            tx_line <= 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        WRITE_next_state = WRITE_state;
        case(WRITE_state)
            WRITE_IDLE: begin
                if (!write_fifo_empty)
                    WRITE_next_state = WRITE_WAIT;
                else
                    WRITE_next_state = WRITE_IDLE;
            end
            WRITE_WAIT: begin
                if (write_fifo_out_valid)
                    WRITE_next_state = WRITE_EXEC;
                else if (wait_counter >= 4)
                    WRITE_next_state = WRITE_IDLE; 
            end
            WRITE_EXEC: begin
                if (bit_idx == 10) 
                    WRITE_next_state = WRITE_IDLE; 
            end
        endcase
    end

// READ FSM
always @(posedge clk) begin
    if (rst) begin
        READ_state <= READ_IDLE;
        read_bit <= 0;
        read_baud_cnt <= 0;
        read_fifo_write_en <= 0;
    end else begin
        READ_state <= READ_next_state;
        read_fifo_write_en <= 0;
        case (READ_state)
            READ_IDLE: begin
                read_bit <= 0;
                read_baud_cnt <= 0;
            end

            READ_WAIT: begin
                read_baud_cnt <= read_baud_cnt + 1;
                if(read_baud_cnt == BAUD_TICKS/2)
                    read_baud_cnt <= 0;
            end

            READ_DETECT: begin
                read_baud_cnt <= read_baud_cnt + 1;
                if (read_baud_cnt == BAUD_TICKS - 1) begin
                    read_baud_cnt <= 0;
                    read_storage[read_bit] <= rx_line;
                    read_bit <= read_bit + 1;
                end
            end
            READ_STOP: begin
                read_baud_cnt <= read_baud_cnt + 1;
                if(read_baud_cnt == BAUD_TICKS - 1) begin
                    read_baud_cnt <= 0;
                end
            end
            READ_WRITE: begin
                read_fifo_write_en <= 1;
                read_fifo_data     <= read_storage;
            end
        endcase
    end
end

// Next-state logic
always @(*) begin
    READ_next_state = READ_state;
    case (READ_state)
        READ_IDLE:
            if (rx_line == 0)
                READ_next_state = READ_WAIT;
        READ_WAIT:
            if (read_baud_cnt == BAUD_TICKS /2)
                READ_next_state = READ_DETECT;
        READ_DETECT:
            if (read_bit == 8)
                READ_next_state = READ_STOP;
        READ_STOP:
            if (read_baud_cnt == BAUD_TICKS - 1) begin
                READ_next_state = READ_WRITE;
                end
        READ_WRITE:
            READ_next_state = READ_IDLE;
    endcase
end

// READ FIFO to CPU
always @(posedge clk) begin
    read_fifo_read_en <= 0;
    if (rst) begin
        rx_data_output <= 0;
        rx_ready       <= 0;
    end 
    else begin
        if (read_fifo_out_valid) begin
            rx_ready <= 1;
            rx_data_output <= {24'b0, read_fifo_output};
        end
        else if (!rx_ready && !read_fifo_empty) begin
            read_fifo_read_en <= 1;
        end
        else if (cpu_read)
            rx_ready <= 0;
    end
end


endmodule