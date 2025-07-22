module pll(
    input sys_clk,
    output pll_clk, pll_lock
);
rPLL #( // For GW1NR-9C C6/I5 (Tang Nano 9K proto dev board)
  .FCLKIN("27"),
  .IDIV_SEL(8), // -> PFD = 3 MHz (range: 3-400 MHz)
  .FBDIV_SEL(39), // -> CLKOUT = 120 MHz (range: 3.125-600 MHz)
  .ODIV_SEL(4) // -> VCO = 480 MHz (range: 400-1200 MHz)
) pll (.CLKOUTP(), .CLKOUTD(), .CLKOUTD3(), .RESET(1'b0), .RESET_P(1'b0), .CLKFB(1'b0), .FBDSEL(6'b0), .IDSEL(6'b0), .ODSEL(6'b0), .PSDA(4'b0), .DUTYDA(4'b0), .FDLY(4'b0),
  .CLKIN(sys_clk), // 27 MHz
  .CLKOUT(pll_clk), // 120 MHz
  .LOCK(pll_lock)
);
endmodule