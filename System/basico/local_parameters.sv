module adder_carry #(parameter N=4)(
  input logic [N-1:0] a, b,
  output logic cout,
  output logic [N-1:0] sum
);

  localparam N1 = N-1;

  logic [N:0] sum_ext;

  assign sum_ext = {1'b0, a} + {1'b0, b};
  assign sum = sum_ext[N1:0];
  assign cout = sum_ext[N];

endmodule

// ======================================================

`timescale 1ns/1ps
module tb_adder_carry;

  // Parâmetro para o tamanho do vetor
  parameter N = 4;

  // Entradas e saídas
  logic [N-1:0] a, b;
  logic [N-1:0] sum;
  logic cout;

  // Instância do DUT (Device Under Test)
  adder_carry #(N) dut (
    .a(a),
    .b(b),
    .sum(sum),
    .cout(cout)
  );

  initial begin
    // Exibe o cabeçalho
    $display("Time\t a\t b\t sum\t cout");
    $display("----------------------------------");

    // Teste 1
    a = 4'b0001; b = 4'b0010; #10;
    $display("%0t\t %b\t %b\t %b\t %b", $time, a, b, sum, cout);

    // Teste 2
    a = 4'b1111; b = 4'b0001; #10;
    $display("%0t\t %b\t %b\t %b\t %b", $time, a, b, sum, cout);

    // Teste 3
    a = 4'b1010; b = 4'b0101; #10;
    $display("%0t\t %b\t %b\t %b\t %b", $time, a, b, sum, cout);

    // Teste 4
    a = 4'b1111; b = 4'b1111; #10;
    $display("%0t\t %b\t %b\t %b\t %b", $time, a, b, sum, cout);

    // Finaliza a simulação
    $finish;
  end

endmodule
