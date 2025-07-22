module uart_decoder(
    input wire clk,
    input wire uart_tx
);
    parameter BAUD_DIV = 434;
    reg [13:0] clk_cnt = 0;
    reg [3:0] bit_cnt = 0;
    reg [7:0] shift_reg = 0;
    reg sampling = 0;

    always @(posedge clk) begin
        if (!sampling && !uart_tx) begin
            sampling <= 1;
            clk_cnt <= BAUD_DIV / 2;  // sample in middle of start bit
            bit_cnt <= 0;
        end else if (sampling) begin
            if (clk_cnt == 0) begin
                clk_cnt <= BAUD_DIV;
                bit_cnt <= bit_cnt + 1;

                if (bit_cnt > 0 && bit_cnt <= 8) begin
                    shift_reg <= {uart_tx, shift_reg[7:1]};
                end

                if (bit_cnt == 9) begin
                    $write("%c", shift_reg);
                    sampling <= 0;
                end
            end else begin
                clk_cnt <= clk_cnt - 1;
            end
        end
    end
endmodule