`timescale 1ns/1ns
`include "porta_and.sv"

module tb_porta_and;

  logic a, b, x;

  porta_and UUT (
    .A(a),
    .B(b),
    .X(x),
  );

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_porta_and);
    a = 0;
    b = 0;
    #10
    a = 0;
    b = 1;
    #10
    a = 1;
    b = 0;
    #10
    a = 1;
    b = 1;
    #10
    $finish
  end

endmodule