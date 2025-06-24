`timescale 1ns/1ns
`include "maquina_estados.sv"

module tb_maquina_estados;

logic clk, n_rst, entrada, saida;

maquina_estados UUT(
  .clk(clk),
  .n_rst(n_rst),
  .entrada(entrada),
  .saida(saida)
);
  initial begin
    $dumpfile("waveform_maquina_estados.vcd");
    $dumpvars(0, tb_maquina_estados);
  end

  // Clock
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Reset
  initial begin
    n_rst = 1'b1;
    #5 n_rst = 1'b0;
    #1 n_rst = 1'b1;
  end

  // Entrada
  initial begin
    entrada = 1'b0;
    #16 entrada = 1'b1; #1 entrada = 1'b0;
    #20 entrada = 1'b1; #1 entrada = 1'b0;
    #20 entrada = 1'b1; #1 entrada = 1'b0;
    #10 entrada = 1'b1; #1 entrada = 1'b0;
    #50 $finish
  end

endmodule