module top (
  ports
);
  
  pll PLL_U0

  clock_div #(.CLK_IN(PLL_FREQ), .CLK_OUT(16*UART_BAUD_RATE)) CLK_DIV_U0(
    .clk_in(pll_clk),
    .n_rst(n_rst),
    .clk_out(clk)
  );

  clk, n_rst, uart_ready_in, uart_valid_in, spi_ready_in, spi_valid_in,

  bmp_280_ctrl #(.DATA_BITS(DATA_BITS)) BMP280_U0(
    // Entradas
    .clk(clk),
    .n_rst(n_rst),
    .uart_ready_in(),
    .uart_valid_in(),
    .spi_ready_in(),
    .spi_valid_in(),
    .uart_data_in(),
    .spi_data_in(),
    // Saídas
    .tied_SS(),
    .spi_en(),
    .uart_en(),
    .uart_data_out(),
    .spi_data_out(),
    .spi_data_words()
  );

  spi_master #(.DATA_BITS(DATA_BITS), .CPOL(0), .BRDV(4), .LSBF(0))

endmodule