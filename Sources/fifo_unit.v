`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2025 12:31:49 PM
// Design Name: 
// Module Name: fifo_unit
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

module fifo_unit #( parameter DEPTH = 32, parameter WIDTH = 8 ) (
    input  wire               clk,
    input  wire               rst,
    input  wire               fifo_write_en,
    input  wire [WIDTH-1:0]   fifo_write_data,
    input  wire               fifo_read_en,
    output wire               fifo_full,
    output wire               fifo_empty,
    output reg                fifo_out_valid,
    output reg  [WIDTH-1:0]   fifo_output
);

    localparam ADDR_WIDTH = clog2(DEPTH);

    reg [WIDTH-1:0] FIFO [DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] wr_ptr = 0;
    reg [ADDR_WIDTH-1:0] rd_ptr = 0;
    reg [ADDR_WIDTH:0]   count  = 0; // one extra bit for full detection

    assign fifo_full  = (count >= DEPTH - 3); // conservative
    assign fifo_empty   = (count == 0);

    always @(posedge clk) begin
    if (fifo_write_en)
        $display("writeData: %h", fifo_write_data);
    if (fifo_out_valid)
        $display("fifoOut: %h", fifo_output);

    if (rst) begin
        wr_ptr         <= 0;
        rd_ptr         <= 0;
        count          <= 0;
        fifo_out_valid <= 0;
    end else begin
        fifo_out_valid <= 0;

        case ({fifo_write_en && !fifo_full, fifo_read_en && !fifo_empty})
            2'b10: begin // write only
                FIFO[wr_ptr] <= fifo_write_data;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
                count  <= count + 1;
            end

            2'b01: begin // read only
                fifo_output    <= FIFO[rd_ptr];
                rd_ptr         <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                count          <= count - 1;
                fifo_out_valid <= 1;
            end

            2'b11: begin // simultaneous read and write
                FIFO[wr_ptr]   <= fifo_write_data;
                fifo_output    <= FIFO[rd_ptr];
                wr_ptr         <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
                rd_ptr         <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                // count stays the same
                fifo_out_valid <= 1;
            end

            default: ; // no op
        endcase
    end
end

    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

endmodule


