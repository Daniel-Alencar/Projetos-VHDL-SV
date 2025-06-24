module prioenconder4x2(
  input logic[3:0] d,
  output logic[1:0] o
);
  always_comb
  begin
    if(d[3] == 1)
      o = 2'b11;
    else if(d[2] == 1)
      o = 2'b10;
    else if(d[1] == 1)
      o = 2'b01;
    else
      o = 2'b00;
  end
endmodule