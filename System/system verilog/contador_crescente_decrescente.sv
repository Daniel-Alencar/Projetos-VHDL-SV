module counter #(parameter N = 4)(
    input logic clk, rst, en, updown,
    output logic[N-1:0] q
);

  logic[N-1:0] q_next, q_reg;

  // REGISTRADOR Q
  always_ff @(posedge clk, posedge rst)
  begin
    if (rst == 1)
      q_reg <= 0;
    else if (en == 1)
      q_reg <= q_next;
  end

  // LÓGICA DO PRÓXIMO ESTADO
  always_comb
  begin
    if (updown == 1)
      q_next = q_reg - 1;
    else
      q_next = q_reg + 1;
  end

  // LÓGICA DE SAÍDA
  assign q = q_reg;

endmodule
