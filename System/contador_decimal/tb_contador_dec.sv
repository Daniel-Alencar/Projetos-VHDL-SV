`timescale 1ns/1ns

// Importações
`include "contador_dec.sv"

// Módulos usados
module tb_contador_dec;

  // Inicialização das variáveis
  logic clk = 0;
  reg [3:0] cnt;

  // Configuração dos módulos 

  // tb_contador_dec
  contador_dec UUT(
    .CLK(clk),
    .CNT(cnt)
  );

  // EXECUÇÕES
  initial begin
    // Descarrega arquivo 
    $dumpfile("waveform.vcd");
    // Descarrega todas as variáveis do test bench
    $dumpvars(0, tb_contador_dec);

    forever #1 clk = ~clk;
  end

  initial begin
    // Depois de 60ns de inicialização da simulação, ela finaliza 
    #60;
    $finish;
  end
endmodule