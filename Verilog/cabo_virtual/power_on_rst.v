module power_on_rst(
    input clk_in, clk_locked,
    //output rst_out,
    output n_rst_out
); 
// Declaração do sinal de reset (ativo durante os primeiros 16 ciclos de clock)   
reg [15:0] rst_reg = 16'hFFFF;
// Deslocamento de bit
always @(posedge clk_in)
if (clk_locked)
rst_reg <= rst_reg >> 1;

// Direcionamento dos registradores para as saídas
//assign rst_out = rst_reg[0];
assign n_rst_out = ~rst_reg[0];
endmodule