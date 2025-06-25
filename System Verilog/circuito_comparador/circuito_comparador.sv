module porta_AND (
  input A, B,
  output X
);
  assign X = A & B;
endmodule

module porta_NOT (
  input A,
  output X
);
  assign X = ~A;
endmodule

module porta_XOR (
  input A, B,
  output X
);
  assign X = A ^ B;
endmodule

module comparador_2bits (
  input [1:0] A,
  input [1:0] B,
  output X
);

  logic X0, X1, X00, X11;

  porta_XOR xor0 (.A(A[0]), .B(B[0]), .X(X0));
  porta_XOR xor1 (.A(A[1]), .B(B[1]), .X(X1));
  porta_NOT not0 (.A(X0), .X(X00));
  porta_NOT not1 (.A(X1), .X(X11));
  porta_AND and0 (.A(X00), .B(X11), .X(X));

endmodule
