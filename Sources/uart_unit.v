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
    output wire       fifo_full,
    output reg        uart_output_line
);

    // UART Parameters
    parameter CLOCK_FREQ = 50_000_000;   // 50 MHz
    parameter BAUD_RATE  = 115200;
    localparam BAUD_TICKS = CLOCK_FREQ / BAUD_RATE;

    // FIFO interface signals
    reg         fifo_read_en;
    wire        fifo_out_valid;
    wire [7:0]  fifo_output;
    reg  [7:0]  fifo_output_storage;

    // UART transmission control
    reg  [9:0]  shift_reg;   // {stop_bit, data[7:0], start_bit}
    reg  [4:0]  bit_idx;
    reg  [15:0] baud_cnt;

    wire [1:0] IDLE = 2'b00;
    wire [1:0] WAIT = 2'b01;
    wire [1:0] EXEC = 2'b10;

    reg  [1:0] state, next_state;

    // Wait counter for timeout in WAIT state
    reg [2:0] wait_counter;

    // Instantiate FIFO
    fifo_unit #(
        .DEPTH(DEPTH),
        .WIDTH(8)
    ) tx_fifo (
        .clk(clk),
        .rst(rst),
        .fifo_write_en(uart_fifo_write_en),
        .fifo_write_data(uart_fifo_data),
        .fifo_read_en(fifo_read_en),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_out_valid(fifo_out_valid),
        .fifo_output(fifo_output)
    );

    // FSM sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            fifo_read_en <= 0;
            wait_counter <= 0;
            uart_output_line <= 1;
            shift_reg <= 10'b1111111111;
            bit_idx <= 0;
            baud_cnt <= 0;
        end else begin
            state <= next_state;
            case(state)
                IDLE: begin
                    if(!fifo_empty)
                        fifo_read_en <= 1;
                    else
                        fifo_read_en <= 0;
                    wait_counter <= 0;
                    uart_output_line <= 1;
                    bit_idx <= 0;
                    baud_cnt <= 0;
                end
                WAIT: begin
                    fifo_read_en <= 0;
                    fifo_output_storage <= fifo_output;
                    wait_counter <= wait_counter + 1;
                end
                EXEC: begin
                    shift_reg <= {1'b1, fifo_output_storage, 1'b0};
                    baud_cnt <= baud_cnt + 1;
                    if (baud_cnt == BAUD_TICKS - 1) begin
                        baud_cnt <= 0;
                        uart_output_line <= shift_reg[bit_idx];
                        bit_idx <= bit_idx + 1;
                        if (bit_idx == 10)
                            uart_output_line <= 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case(state)
            IDLE: begin
                if (!fifo_empty)
                    next_state = WAIT;
                else
                    next_state = IDLE;
            end
            WAIT: begin
                if (fifo_out_valid)
                    next_state = EXEC;
                else if (wait_counter >= 4)
                    next_state = IDLE; 
            end
            EXEC: begin
                if (bit_idx == 10) 
                    next_state = IDLE; 
            end
        endcase
    end
endmodule