module blink #(CLK_IN=120000000, BLINK_FREQ=1)(
    input clk,
    output led_out
);    
localparam DIV = (CLK_IN/(BLINK_FREQ*2))-1;
reg [$clog2(DIV)-1:0] clk_cnt = 0;
reg led_reg = 1'b0;    
always @(posedge clk)begin
    if (clk_cnt == DIV) begin
        clk_cnt <= 0;
        led_reg <= ~led_reg;
    end
    else
    clk_cnt <= clk_cnt + 1;
end    
assign led_out = led_reg;        
endmodule
