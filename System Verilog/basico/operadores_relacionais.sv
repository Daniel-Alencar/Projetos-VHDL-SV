module tb_operadores;
  logic [3:0] a, b, c;

  initial
  begin
    a = 4'b0110;
    b = 4'b1001;

    if (a > b)
      $display("A maior do que B");

    if (a < b)
      $display("A menor do que B");

    if (a >= b)
      $display("A maior ou igual do que B");

    if (a <= b)
      $display("A menor ou igual do que B");

    if (a == b)
      $display("A igual B");

    if (a != b)
      $display("A diferente B");

    $finish;
  end
endmodule
