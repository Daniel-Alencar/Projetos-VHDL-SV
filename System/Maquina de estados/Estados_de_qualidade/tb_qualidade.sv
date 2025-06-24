`timescale 1ns/1ns
`include "qualidade.sv"

module tb_qualidade;

  logic clk, n_rst, presenca, rgb, rgb_valido;
  logic [1:0] leds;

  qualidade UUT(
    .clk(clk),
    .n_rst(n_rst),
    .presenca(presenca),
    .rgb(rgb),
    .rgb_valido(rgb_valido),
    .leds(leds)
  );

  initial begin
    $dumpfile("waveform_qualidade.vcd");
    $dumpvars(0, tb_qualidade);
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

  // Entradas
  initial begin
    presenca = 1'b0;
    rgb = 1'b0;
    rgb_valido = 1'b0;
    #12 presenca = 1'b1;
    #25 rgb = 1'b1;
    rgb_valido = 1'b1; #1 rgb_valido = 1'b0;
    #10 presenca = 1'b0;
    #10 presenca = 1'b1;
    #10 rgb = 1'b1;
    rgb_valido = 1'b1; #1 rgb_valido = 1'b0;
    #20 presenca = 1'b0;
    #10 $finish;
  end
  
endmodule