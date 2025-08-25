`timescale 1ns / 1ns
module tb_project_design_wrapper;
// Entradas do testbench
reg clk_reg;
reg rx_reg;
// Saídas do testbench
wire led_D2;
wire tx;
// Instanciação do projeto
project_design_wrapper UUT(
    .dev_clk(clk_reg),
    .rx(rx_reg),
    .led_D2(led_D2),
    .tx(tx)
);
initial begin
    clk_reg = 1'b0;
    forever #1 clk_reg = ~clk_reg;
end
initial begin
    rx_reg = 1'b1;
    // letra "w" (01110111) LSB
    #41 rx_reg = 1'b0;  // start
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b0;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b0;
    #32 rx_reg = 1'b1;  // stop
    // letra "r" (01110010) LSB
    #64 rx_reg = 1'b0;  // start
    #32 rx_reg = 1'b0;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b0;
    #32 rx_reg = 1'b0;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b1;
    #32 rx_reg = 1'b0;
    #32 rx_reg = 1'b1;  // stop
    #10000 $finish;
end
endmodule