`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/21/2025 09:52:34 AM
// Design Name: 
// Module Name: imem
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
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/21/2025 09:52:34 AM
// Design Name: 
// Module Name: imem
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
module imem(
    input wire [31:0] PC,
    output reg [31:0] inst,
    output reg [4:0] rd,
    output reg [4:0] rs1,
    output reg [4:0] rs2
    );
    
    reg [7:0] inst_mem [0:1599]; 
    
    initial begin
        $readmemh("U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test.mem", inst_mem);
    end
    
    always @(*) begin
        inst = {inst_mem[PC + 3], inst_mem[PC + 2], inst_mem[PC + 1], inst_mem[PC]};
        rd  = inst[11:7];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
    end

endmodule
