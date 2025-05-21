`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2025 11:48:23 AM
// Design Name: 
// Module Name: branch_comp_tb
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

module tb_branch_comp;
    reg sign_select;
    reg [31:0] rdata1;
    reg [31:0] rdata2;
    wire equal;
    wire less_than;
    
    branch_comp uut (
        .sign_select(sign_select),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .equal(equal),
        .less_than(less_than)
    );
    
    initial begin
        
        #10;
        sign_select = 0;     
        rdata1 = 32'd10;
        rdata2 = 32'd20;
        
        #10;
        sign_select = 1;     
        rdata1 = 32'd10;
        rdata2 = 32'd20;
        
        #10;
        sign_select = 0;     
        rdata1 = 32'd20;
        rdata2 = 32'd20;
        
        #10;
        sign_select = 1;     
        rdata1 = 32'd20;
        rdata2 = 32'd20;
        
        #10;
        sign_select = 0;     
        rdata1 = 32'd30;
        rdata2 = 32'd20;
        
        #10;
        sign_select = 1;     
        rdata1 = 32'd30;
        rdata2 = 32'd20;
        
        #10;
        sign_select = 1;     
        rdata1 = 32'hffff0000;
        rdata2 = 32'hffffffff;
        
        #10;
        sign_select = 0;     
        rdata1 = 32'hffff0000;
        rdata2 = 32'hffffffff;
        
        #10;
        sign_select = 1;     
        rdata1 = 32'h0fff0000;
        rdata2 = 32'hffffffff;
        
        #10;
        sign_select = 0;     
        rdata1 = 32'h0fff0000;
        rdata2 = 32'hffffffff;
        end
endmodule

