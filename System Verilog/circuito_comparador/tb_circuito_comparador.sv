`timescale 1ns/1ns
`include "circuito_comparador.sv"

module tb_comparador_2bits;

  // Inicialização das variáveis
  logic [1:0] A, B;
  logic X;

  // Instanciando o comparador
  comparador_2bits UUT (
    .A(A),
    .B(B),
    .X(X)
  );

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_comparador_2bits);

    A = 2'b10; B = 2'b11; #10;
    A = 2'b01; B = 2'b01; #10;
    A = 2'b10; B = 2'b10; #10;
    A = 2'b10; B = 2'b01; #10;

    $finish;
  end
endmodule
