`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2025 12:11:09 PM
// Design Name: 
// Module Name: dmem_tb
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

module dmem_tb;
    reg clk;
    reg RW;
    reg [2:0] funct3;
    reg [31:0] address;
    reg [31:0] wdata;
    wire [31:0] rdata;
    wire exception;
    wire [3:0] exception_code;

    // Instantiate the memory module
    dmem uut (
        .clk(clk),
        .RW(RW),
        .funct3(funct3),
        .address(address),
        .wdata(wdata),
        .rdata(rdata),
        .exception(exception),
        .exception_code(exception_code)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Time\tRW\tfunct3\tAddr\t\tWData\t\tRData");
        $monitor("%0t\t%b\t%03b\t%h\t%h\t%h", $time, RW, funct3, address, wdata, rdata);

        clk = 0;
        RW = 0;
        funct3 = 3'b000;
        address = 0;
        wdata = 0;

        // ===== WRITE PHASE =====

        #10;
        RW = 1;
        funct3 = 3'b010; // sw
        address = 32'h00000000;
        wdata = 32'hABCDEF00;

        #10;
        funct3 = 3'b000; // sb (store byte to offset 0 of word 0xC)
        address = 32'h0000000C;
        wdata = 32'h000000AA;
        
        #10
        address = 32'h0000000D;
        wdata = 32'h000000BB;

        #10;
        funct3 = 3'b001; // sh (store halfword to offset 2 of word 0x10)
        address = 32'h00000010;
        wdata = 32'h0000FFFF;
        
        #10
        address = 32'h00000012;
        wdata = 32'h0000AAAA;
        
        

        // ===== READ PHASE =====

        #10;
        RW = 0;
        funct3 = 3'b010; // lw
        address = 32'h00000000;

        #10;
        address = 32'h0000000C;

        #10;
        address = 32'h00000010;
        
        #10 
        address = 32'h0000000D;
        
        #10
        address = 32'h00000012;


        #10;
        funct3 = 3'b100; // lbu
        address = 32'h0000000C;

        #10;
        funct3 = 3'b000; // lb (signed)
        address = 32'h0000000C;

        #10;
        funct3 = 3'b101; // lhu
        address = 32'h00000010;

        #10;
        funct3 = 3'b001; // lh (signed)
        address = 32'h00000010;
        
        #10
        address = 32'h00000012;
        
        #10
        address = 32'h0000000D;
        


        #10;
        $finish;
    end
endmodule
