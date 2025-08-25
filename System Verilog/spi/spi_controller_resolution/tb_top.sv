`timescale 1ns/1ns
`include "top.sv"
`include "spi_master.sv"
`include "spi_master_ctrl.sv"

module tb_top;

    reg sys_clk, n_rst, enable, MISO, ready_out, valid_out, SCK, SS, MOSI;
    reg [7:0] reg_1_out, reg_2_out, reg_3_out, reg_4_out;

    top #(.DATA_BITS(8)) TOP_U0 (
        .sys_clk(sys_clk),
        .n_rst(n_rst),
        .enable(enable),
        .MISO(MISO),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .SCK(SCK),
        .SS(SS),
        .MOSI(MOSI),
        .reg_1_out(reg_1_out),
        .reg_2_out(reg_2_out),
        .reg_3_out(reg_3_out),
        .reg_4_out(reg_4_out)
    );


    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
    end

    initial begin
        n_rst = 1'b1;
        #4 n_rst = 1'b0;
        #4 n_rst = 1'b1;
    end

    initial begin
        sys_clk = 1'b0;
        forever #1 sys_clk = ~sys_clk;
    end

    initial begin
        enable = 1'b0;
        MISO = 1'b1;
        #10 enable = 1'b1; #2 enable = 1'b0;
        #320
        $finish;
    end

    always_ff @(posedge valid_out)
        MISO <= ~MISO;

endmodule
