`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chris Tian
// 
// Create Date: 05/21/2025 12:00:38 PM
// Design Name: 
// Module Name: dmem
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


module dmem(
    input wire clk,
    input wire RW, // 1 = write, 0 = read
    input wire [2:0] funct3,
    input wire [31:0] address,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    output wire exception,
    output wire [3:0] exception_code
    );
    
    reg [31:0] dmem [127:0];
    initial begin
        dmem[0] <= 0;
        rdata <= 0;
    end
    
    assign exception = ((address[0] || address[1]) && funct3 == 3'b010 ) || //word
                       ((address[0]) && funct3 == 3'b001 ); //haldword

    assign exception_code = RW; // read wrong 0, write wrong 1

    always @(posedge clk) begin        
        if(!exception) begin
        if (RW) begin
            // write
            case(funct3)
                3'b000: begin // sb
                    case(address[1:0])
                        2'b00: dmem[address[31:2]][7:0]   <= wdata[7:0];
                        2'b01: dmem[address[31:2]][15:8]  <= wdata[7:0];
                        2'b10: dmem[address[31:2]][23:16] <= wdata[7:0];
                        2'b11: dmem[address[31:2]][31:24] <= wdata[7:0];
                    endcase
                end
                3'b001: begin // sh 
                    case(address[1])
                        1'b0: dmem[address[31:2]][15:0]  <= wdata[15:0];
                        1'b1: dmem[address[31:2]][31:16] <= wdata[15:0];
                    endcase
                end
                3'b010: begin // sw 
                    dmem[address[31:2]] <= wdata;
                end
            endcase
        end else begin
            // read
            case(funct3)
                3'b000: begin // lb  sign-extend
                    case(address[1:0])
                        2'b00: rdata <= {{24{dmem[address[31:2]][7]}},   dmem[address[31:2]][7:0]};
                        2'b01: rdata <= {{24{dmem[address[31:2]][15]}},  dmem[address[31:2]][15:8]};
                        2'b10: rdata <= {{24{dmem[address[31:2]][23]}},  dmem[address[31:2]][23:16]};
                        2'b11: rdata <= {{24{dmem[address[31:2]][31]}},  dmem[address[31:2]][31:24]};
                    endcase
                end
                3'b100: begin // lbu zero-extend
                    case(address[1:0])
                        2'b00: rdata <= {{24{1'b0}}, dmem[address[31:2]][7:0]};
                        2'b01: rdata <= {{24{1'b0}}, dmem[address[31:2]][15:8]};
                        2'b10: rdata <= {{24{1'b0}}, dmem[address[31:2]][23:16]};
                        2'b11: rdata <= {{24{1'b0}}, dmem[address[31:2]][31:24]};
                    endcase
                end
                3'b001: begin // lh sign-extend
                    case(address[1])
                        1'b0: rdata <= {{16{dmem[address[31:2]][15]}}, dmem[address[31:2]][15:0]};
                        1'b1: rdata <= {{16{dmem[address[31:2]][31]}}, dmem[address[31:2]][31:16]};
                    endcase
                end
                3'b101: begin // lhu zero-extend
                    case(address[1])
                        1'b0: rdata <= {{16{1'b0}}, dmem[address[31:2]][15:0]};
                        1'b1: rdata <= {{16{1'b0}}, dmem[address[31:2]][31:16]};
                    endcase
                end
                3'b010: begin // lw
                    rdata <= dmem[address[31:2]];
                end
                default: rdata <= 32'b0;
            endcase
        end
        end
    end
endmodule