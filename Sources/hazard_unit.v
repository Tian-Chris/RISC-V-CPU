`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2025 03:02:07 PM
// Design Name: 
// Module Name: hazard_unit
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


module hazard_unit (
    input  wire [4:0] IFrs1,
    input  wire [4:0] IFrs2,
    input  wire [4:0] IDrd,
    input  wire IDmemRead,

    //flush
    input  wire PCSel,
    input  wire jump_taken,

    //MMU Stall
    input  wire stall_IMEM,
    input  wire stall_DMEM,

    output reg [3:0] hazard_signal
);
    `include "inst_defs.v"
    always @(*) begin
        if(PCSel)
            hazard_signal = `FLUSH_ALL;
        else if(jump_taken)
            hazard_signal = `FLUSH_EARLY;
        else if(stall_IMEM || stall_DMEM)
            hazard_signal = `STALL_MMU; 
        else if(IDmemRead && (IDrd != 0) && ((IDrd == IFrs1) || (IDrd == IFrs2)))
            hazard_signal = `STALL_EARLY; 
        else
            hazard_signal = `HS_DN;
        `ifdef DEBUG_HAZARD
            $display("===========  HAZARD  ===========");
            $display("hazard_signal: %b", hazard_signal);
        `endif
    end
endmodule
