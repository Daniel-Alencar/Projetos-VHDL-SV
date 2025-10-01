module blink #(CLK_IN_MHZ=100, BLINK_FREQ_HZ=2)(
    input clk_in, n_rst,
    output led_out
);
// Cálculo do divisor de clock
localparam DIV = (CLK_IN_MHZ*10**6/(BLINK_FREQ_HZ*2))-1;
// Declaração do registrador para contagem de clock
reg [$clog2(DIV)-1:0] clk_cnt = 0;
// Divisor de frequência de clock
reg led_reg = 1'b0;
always @(posedge clk_in, negedge n_rst)
if (~n_rst) begin
    clk_cnt <= 0;
    led_reg <= 1'b0;
end
else begin
    if (clk_cnt == DIV) begin
        clk_cnt <= 0;
        led_reg <= ~led_reg;
    end
    else
    clk_cnt <= clk_cnt + 1;
end
// Direcionamento do registrador para a saída
assign led_out = led_reg;
endmodule
