`timescale 1ns / 1ps

module uart_unit_tb;

    // Clock and Reset
    reg clk = 0;
    reg rst = 1;

    // UART I/O
    reg         uart_fifo_write_en = 0;  // not used for read test
    reg  [7:0]  uart_fifo_data = 0;      // not used for read test
    reg         cpu_read = 0;
    reg         rx_line = 1;  // idle = high
    wire        tx_line;      // unused here
    wire        rx_ready;
    wire        tx_ready;     // unused here
    wire        write_fifo_full;  // unused here
    wire [31:0] rx_data_output;

    // Instantiate UART (DEPTH parameter optional)
    uart_unit #(.DEPTH(8)) uut (
        .clk(clk),
        .rst(rst),
        .uart_fifo_write_en(uart_fifo_write_en),
        .uart_fifo_data(uart_fifo_data),
        .cpu_read(cpu_read),
        .rx_line(rx_line),
        .tx_line(tx_line),
        .rx_ready(rx_ready),
        .tx_ready(tx_ready),
        .write_fifo_full(write_fifo_full),
        .rx_data_output(rx_data_output)
    );

    // Clock generation: 20ns period (50MHz)
    always #10 clk = ~clk;

    // Constants for UART timing
    localparam BAUD_RATE = 115200;
    localparam CLOCK_FREQ = 50_000_000;
    localparam BIT_TIME = 1_000_000_000 / BAUD_RATE;  // ns per bit

    // Task: simulate receiving one byte on UART RX line (LSB first)
    task uart_receive_byte(input [7:0] data);
        integer i;
        begin
            // Start bit (0)
            rx_line = 0;
            #(BIT_TIME);
            // Data bits
            for (i = 0; i < 8; i = i + 1) begin
                rx_line = data[i];
                #(BIT_TIME);
            end
            // Stop bit (1)
            rx_line = 1;
            #(BIT_TIME);
        end
    endtask

    initial begin
        // Reset pulse
        #50 rst = 0;

        // Wait a few cycles for UART to stabilize
        #100;

        // Send one byte over UART RX line
        $display("Sending byte 0x5A over UART RX...");
        uart_receive_byte(8'h5A);
        uart_receive_byte(8'hFF);
        uart_receive_byte(8'h55);

        // Wait for rx_ready to go high
        wait(rx_ready == 1);
        @(posedge clk);

        $display("rx_ready is high, data received: 0x%02x", rx_data_output[7:0]);

        // Simulate CPU reading the byte
        cpu_read = 1;
        @(posedge clk);
        cpu_read = 0;

        // Wait a bit and check rx_ready cleared
        #50;
        if (rx_ready == 0)
            $display("CPU read acknowledged, rx_ready cleared.");
        else
            $display("Error: rx_ready did not clear after CPU read.");
                    $display("rx_ready is high, data received: 0x%02x", rx_data_output[7:0]);

        // Simulate CPU reading the byte
        @(posedge clk);
        cpu_read = 1;
        @(posedge clk);
        cpu_read = 0;
        @(posedge clk);

        // Wait a bit and check rx_ready cleared
        #50;
        if (rx_ready == 0)
            $display("CPU read acknowledged, rx_ready cleared.");
        else
            $display("Error: rx_ready did not clear after CPU read.");
                    $display("rx_ready is high, data received: 0x%02x", rx_data_output[7:0]);
@(posedge clk);
        // Simulate CPU reading the byte
        cpu_read = 1;
        @(posedge clk);
        cpu_read = 0;

        // Wait a bit and check rx_ready cleared
        #50;
        if (rx_ready == 0)
            $display("CPU read acknowledged, rx_ready cleared.");
        else
            $display("Error: rx_ready did not clear after CPU read.");

        #100;
        $finish;
    end

endmodule
