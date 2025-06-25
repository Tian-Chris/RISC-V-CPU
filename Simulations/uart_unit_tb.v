`timescale 1ns / 1ps

module uart_unit_tb;

// Parameters
localparam CLK_PERIOD = 20; // 50 MHz clock -> 20ns

// DUT Parameters
localparam DEPTH = 32;

// Signals
reg clk;
reg rst;
reg uart_fifo_write_en;
reg [7:0] uart_fifo_data;
wire fifo_full;
wire uart_output_line;

// Instantiate the DUT
uart_unit #(
    .DEPTH(DEPTH)
) dut (
    .clk(clk),
    .rst(rst),
    .uart_fifo_write_en(uart_fifo_write_en),
    .uart_fifo_data(uart_fifo_data),
    .fifo_full(fifo_full),
    .uart_output_line(uart_output_line)
);

// Clock Generation
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// Test Stimulus
initial begin
    $display("Starting UART testbench...");

    // Initialize
    rst = 1;
    uart_fifo_write_en = 0;
    uart_fifo_data = 8'h00;

    // Reset pulse
    #(CLK_PERIOD * 10);
    rst = 0;
    // Send first byte
    #(CLK_PERIOD * 10);
    
    uart_fifo_data = 8'hFF;
    uart_fifo_write_en = 1;
    #(CLK_PERIOD);
    uart_fifo_write_en = 0;

    uart_fifo_data = 8'h00;
    uart_fifo_write_en = 1;
    #(CLK_PERIOD);
    uart_fifo_write_en = 0;
        
    uart_fifo_data = 8'hFF;
    uart_fifo_write_en = 1;
    #(CLK_PERIOD);
    uart_fifo_write_en = 0;

    uart_fifo_data = 8'h00;
    uart_fifo_write_en = 1;
    #(CLK_PERIOD);
    uart_fifo_write_en = 0;
    // Observe the output
    #(CLK_PERIOD * 32000);

    $display("UART testbench complete.");
    $finish;
end

// Optional: monitor UART output
initial begin
    $monitor("Time: %0t | UART Line: %b", $time, uart_output_line);
end

endmodule
