module regIP0(
  input logic clk, rst, wr_en,
  input logic [3:0] din,
  output logic [3:0] dout
);

  // q_next é o próximo valor do registrador
  // q_reg é o valor atual do registrador
  logic [3:0] q_next, q_reg;

  // circuito do registrador
  always_ff @(posedge clk, posedge rst)
  begin
    if (rst == 1'b1)
      q_reg <= 0;
    else if (wr_en == 1'b1)
      q_reg <= q_next;
  end

  // lógica do próximo estado do registrador
  assign q_next = din;

  // lógica de saída
  assign dout = q_reg;

endmodule
