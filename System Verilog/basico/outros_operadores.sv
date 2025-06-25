module tb_operadores;
  logic [3:0] a, b;

  initial
  begin
    a = 4'b0110;
    b = 4'b1001;

    // Exibição dos resultados
    $display("Valor do deslocamento a direita: %b", a >> 1);
    $display("Valor do deslocamento a esquerda: %b", a << 1);
    $display("Valor do complemento de a: %b", ~a);
    $display("Valor a and b: %b", a & b);
    $display("Valor a or b: %b", a | b);
    $display("Valor a xor b: %b", a ^ b);

    $finish;
  end
endmodule
