module tb_operadores;
  logic [3:0] a, b, c;

  initial
  begin
    a = 4'b0110;
    b = 4'b0010;

    c = a + b;
    $display("Valor da soma: %b", c);

    c = a - b;
    $display("Valor da subtracao: %b", c);

    c = a * b;
    $display("Valor da multiplicacao: %b", c);

    c = a / b;
    $display("Valor da divisao: %b", c);

    c = a ** b;
    $display("Valor da exponenciacao: %b", c);

    $finish;
  end
endmodule
