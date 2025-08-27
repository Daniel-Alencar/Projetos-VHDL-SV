`timescale 1ns / 1ns
`include "i2c_master.v"

module tb_i2c_master;

reg clk_in, n_rst, rd_wr, i2c_en, continuous, ready_out, valid_out, SCL, SDA;
reg [6:0] address_in;
reg [7:0] wr_data_in;
reg [5:0] wr_data_bytes;

i2c_master #(.OVERSAMPLING(4), .RETRY_NUM(3)) UUT(
    .clk_in(clk_in),
    .n_rst(n_rst),
    .rd_wr(rd_wr),
    .i2c_en(i2c_en),
    .continuous(continuous),
    .address_in(address_in),
    .wr_data_in(wr_data_in),
    .wr_data_bytes(wr_data_bytes),
    .ready_out(ready_out),
    .valid_out(valid_out),
    .SCL(SCL),
    .SDA(SDA)
);

initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_i2c_master);
end

initial begin
    clk_in = 1'b0;
    forever #1 clk_in = ~clk_in;
end

initial begin
    n_rst = 1'b1;
    #1 n_rst = 1'b0;
    #4 n_rst = 1'b1;
end

initial begin
    rd_wr = 1'b0;
    i2c_en = 1'b0;
    continuous = 1'b1;
    address_in = 7'b0101011;
    wr_data_in = 8'b01010101;
    wr_data_bytes = 2;
    #41 i2c_en = 1'b1; #1 i2c_en = 1'b0;
    #400 $finish;
end

endmodule