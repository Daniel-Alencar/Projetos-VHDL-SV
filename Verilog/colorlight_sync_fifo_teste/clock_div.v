module clock_div #(parameter CLK_IN=120000000, CLK_OUT=153600)(
    input clk_in,
    output clk_out
);
// Declaração do registrador para contagem de clock
localparam DIV = ((CLK_IN/CLK_OUT)/2)-1;
reg [$clog2(DIV):0] clk_cnt = 0;reg clk_reg = 1'b0;
// Divisor de frequência de clock
always @(posedge clk_in) begin
    if (clk_cnt == DIV) begin
        clk_reg <= ~clk_reg;
        clk_cnt <= 0;
    end
    else
    clk_cnt <= clk_cnt + 1;
end
// Direcionamento do registrador para a saída
assign clk_out = clk_reg;
endmodule