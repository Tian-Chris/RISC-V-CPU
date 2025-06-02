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
    output wire stall
);
    assign stall = IDmemRead && (IDrd != 0) && ((IDrd == IFrs1) || (IDrd == IFrs2));
endmodule
