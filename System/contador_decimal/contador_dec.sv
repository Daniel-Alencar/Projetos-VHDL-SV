module contador_dec (
  input CLK,
  output [3:0] CNT = 0
);
  always @(posedge CLK) begin
    CNT = CNT + 1;
    if (CNT == 10) begin
      CNT = 0;
    end
  end
  
endmodule