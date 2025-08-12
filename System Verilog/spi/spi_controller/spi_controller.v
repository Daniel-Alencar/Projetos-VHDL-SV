module spi_controller #(parameter DATA_BITS=8) (
    input clk, n_rst, spi_en, MISO,
    input [DATA_BITS-1:0] data_in,
    output SCK, SS, MOSI, ready_out, valid_out,
    output [DATA_BITS-1:0] data_out
);

    spi_master spi_instance (
        .clk(clk),
        .n_rst(n_rst),
        .spi_en(spi_en),
        .tied_SS(1'b1),
        .MISO(MISO),
        .data_in(data_in),
        .data_words(6'b000100),
        .SCK(SCK),
        .SS(SS),
        .MOSI(MOSI),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .data_out(data_out)
    );

endmodule
