module univ_shift_reg
  #(parameter N=4)
  (
    input logic clk, rst,
    input logic [1:0] ctrl,
    input logic [N-1:0] d,
    output logic [N-1:0] q
  );

  logic [N-1:0] r_reg, r_next;

  // registrador R
  always_ff @(posedge clk, posedge rst)
  begin
    if (rst)
      r_reg <= 0;
    else
      r_reg <= r_next;
  end

  // lógica do próximo estado
  always_comb
    case (ctrl)
      2'b00: r_next = r_reg;
      2'b01: r_next = {r_reg[N-2:0], d[0]};
      2'b10: r_next = {d[N-1], r_reg[N-1:1]};
      default: r_next = d;
    endcase

  // saída do circuito
  assign q = r_reg;

endmodule
