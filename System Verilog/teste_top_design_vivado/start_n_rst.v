module start_n_rst(
    input clk_in,
    output n_rst_out
);    
reg [15:0] n_rst_reg = 16'h01;    
always @(posedge clk_in) begin
    n_rst_reg <= n_rst_reg >> 1;
end    
assign n_rst_out = ~n_rst_reg[0];
endmodule