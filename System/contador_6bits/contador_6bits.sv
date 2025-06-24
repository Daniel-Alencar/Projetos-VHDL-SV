module top (
  input CLK, RST,
  output [5:0] CNT
);

  localparam clk_out = 13500000;
  reg [23:0] clk_cnt = 0;
  reg [5:0] led_cnt = 0;

  always @(posedge CLK) begin
    clk_cnt = clk_cnt + 1;

    if(!RST) begin
      clk_cnt = 0;
      led_cnt = 0;
    end else

    if(clk_cnt == clk_out) begin
      led_cnt = led_cnt + 1;
      clk_cnt = 0;
    end
  end

  assign CNT = ~led_cnt;

endmodule