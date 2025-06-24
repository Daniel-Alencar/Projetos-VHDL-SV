module decoder(
  input  logic [1:0] sel,
  input  logic       a, b, c,
  output logic [1:0] r
);

  always_comb begin
    case(sel)
      2'b00:    r = a + b + c;
      2'b10:    r = a - c;
      default:  r = c + 1;
    endcase
  end

endmodule
