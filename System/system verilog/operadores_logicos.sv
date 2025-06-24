module tb_operadores;
  logic [3:0] a, b, c;

  initial
  begin
    a = 4'b0110;
    b = 4'b1001;

    if ( (a > b) && (c < b) )
      $display("Teste 1 Verdadeiro");

    if ( (a > b) || (c < b) )
      $display("Teste 2 Verdadeiro");

    if (( a >= b ))
      $display("Teste 3 Verdadeiro");

    $display("Concatenacao de a e b %b", {a, b});
    $display("Concatenacao e repeticao de padrao %b", {{4{2'b01}}});

    $finish;
  end
endmodule
