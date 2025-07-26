`timescale 1ns / 1ps

module top (
    input sys_clk,
    output led
);
    blink BLINK_U0(
        .clk(sys_clk),
        .led_out(led)
    );
endmodule