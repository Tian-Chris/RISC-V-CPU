`include "inst_defs.v"
module Pipe #(
    parameter STAGE       = `STAGE_ID,
    parameter WIDTH       = 32,
    parameter RESET_VALUE = 0
)(
    input  wire              clk,
    input  wire              rst,
    input  wire [3:0]        hazard_signal,
    input  wire [WIDTH-1:0]  in_data,
    output reg  [WIDTH-1:0]  out_data
);

    always @(posedge clk) begin
        if (rst || hazard_signal == `FLUSH_EXCEPT                  ||
            (hazard_signal == `FLUSH_ALL && STAGE != `STAGE_WB)    || 
            ((hazard_signal == `FLUSH_EARLY && STAGE == `STAGE_ID) || (hazard_signal == `STALL_EARLY && STAGE == `STAGE_EX))) begin
            out_data <= RESET_VALUE;
        end 
        else if(hazard_signal == `STALL_MMU) begin
        end
        else begin
            out_data <= in_data;
        end
    end

endmodule