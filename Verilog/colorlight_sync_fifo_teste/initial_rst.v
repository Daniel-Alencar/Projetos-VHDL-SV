module initial_rst(
    input clk_in,
    output rst_out, n_rst_out
);    
    reg [3:0] rst_reg = 4'b0011;

    always @(posedge clk_in)
        rst_reg <= rst_reg >> 1;
        
    assign rst_out = rst_reg[0];
    assign n_rst_out = ~rst_reg[0];
endmodule