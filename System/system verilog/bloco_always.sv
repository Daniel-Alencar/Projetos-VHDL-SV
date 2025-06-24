module eq1(
  input logic i0, i1,
  output logic eq
);

always_comb
begin
  logic tmp;
  tmp = 1'b0;
  tmp = tmp | (~i0 & ~i1);
  tmp = tmp | (i0 & i1);
  eq = tmp;
end

endmodule
