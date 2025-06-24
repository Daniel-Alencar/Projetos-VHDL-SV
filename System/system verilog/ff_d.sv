module ffd (
  input logic clock, reset, d,
  output logic q
);

  always_ff @(posedge clock, posedge reset) begin
    if (reset == 1'b1) begin
      q <= 1'b0;
    end else begin
      q <= d;
    end
  end

endmodule
