module top #(parameter DATA_BITS=8) (
    input sys_clk, n_rst, enable, MISO,
    output ready_out, valid_out, SCK, SS, MOSI,
    output [DATA_BITS-1:0] reg_1_out, reg_2_out, reg_3_out, reg_4_out
);

    wire [DATA_BITS-1:0] ctrl_spi_data_t;
    wire [5:0] ctrl_spi_data_words;
    wire [DATA_BITS-1:0] reg_1_out, reg_2_out, reg_3_out, reg_4_out;
    wire [DATA_BITS-1:0] spi_ctrl_data;

    spi_master_ctrl #(.DATA_BITS(8)) CTRL_U0(
        // entradas
        .clk_in(sys_clk),
        .n_rst(n_rst),
        .spi_ready_in(spi_ctrl_ready),
        .spi_valid_in(spi_ctrl_valid),
        .enable(enable),
        .spi_data_r(spi_ctrl_data),
        // saídas
        .tied_SS_out(ctrl_spi_tied_SS),
        .spi_en_out(ctrl_spi_en),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .spi_data_t(ctrl_spi_data_t),
        .spi_data_words(ctrl_spi_data_words),
        .reg_1_out(reg_1_out),
        .reg_2_out(reg_2_out),
        .reg_3_out(reg_3_out),
        .reg_4_out(reg_4_out)
    );

    spi_master #(.DATA_BITS(8), .CPOL(0), .CPHA(0), .BRDV(4), .LSBF(0)) SPI_U0(
        // entradas
        .clk_in(sys_clk),
        .n_rst(n_rst),
        .spi_en(ctrl_spi_en),
        .tied_SS(ctrl_spi_tied_SS),
        .MISO(MISO),
        .data_in(ctrl_spi_data_t),
        .data_words(ctrl_spi_data_words),
        // saídas
        .SCK(SCK),
        .SS(SS),
        .MOSI(MOSI),
        .ready_out(spi_ctrl_ready),
        .valid_out(spi_ctrl_valid),
        .data_out(spi_ctrl_data)
    );

endmodule