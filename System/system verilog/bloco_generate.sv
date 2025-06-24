module ou_reduzido 
  #(parameter N=8)
  (
    input logic[N-1:0] a,
    output logic y
  );

  logic [N-1:0] p;

  assign p[0] = a[0];
  
  generate
    genvar i;
    for (i = 1; i < N; i = i + 1)
      assign p[i] = a[i] ^ p[i-1];
  endgenerate

  assign y = p[N-1];

endmodule
