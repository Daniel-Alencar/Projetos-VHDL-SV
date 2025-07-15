module clock_div #(parameter CLK_IN=120000000, CLK_OUT=6000000)(
    input clk_in, n_rst,
    output clk_out
);

// Declaração do registrador para contagem de clock
localparam DIV = ((CLK_IN/CLK_OUT)/2)-1;
reg [$clog2(DIV):0] clk_div = DIV;

// Divisor de frequência de clock (gera sinal clk_reg)
reg [9:0] clk_cnt = 0;
reg clk_reg = 1'b0;

always @(posedge clk_in, negedge n_rst) begin
    if (!n_rst)
        clk_cnt <= 0;
    else begin
        if (clk_cnt == clk_div) begin
            clk_reg <= ~clk_reg;
            clk_cnt <= 0;
        end
        else
            clk_cnt <= clk_cnt + 1;
    end
end

// Direcionamento do registrador para a saída
assign clk_out = clk_reg;

endmodule
