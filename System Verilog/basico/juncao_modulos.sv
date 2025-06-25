module combinational (
  input logic a, b,
  output logic c
);
  logic s1, s2;
  assign s1 = a & b;
  assign s2 = ~a & ~b;
  assign c = s1 | s2;
endmodule

module comparator(
  input logic [1:0] a, b,
  output logic c
);
  logic s1, s2;

  combinational u1 (.a(a[0]), .b(b[0]), .c(s1));
  combinational u2 (.a(a[1]), .b(b[1]), .c(s2));

  assign c = s1 & s2;
endmodule

module tb_comp;
  logic [1:0] a, b;
  logic c;

  comparator dut (.a(a), .b(b), .c(c));

  initial begin
    a = 2'b00;
    b = 2'b00;
    #200;

    a = 2'b01;
    b = 2'b00;
    #200;

    a = 2'b10;
    b = 2'b00;
    #200;

    $stop;
  end
endmodule
