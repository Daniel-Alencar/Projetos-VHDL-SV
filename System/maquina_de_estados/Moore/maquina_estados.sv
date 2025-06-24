module maquina_estados (
  input logic clk, n_rst, entrada,
  output logic saida
);

  logic [1:0] estado_presente = 2'b00;
  logic [1:0] proximo_estado = 2'b00;

  always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst)
      estado_presente <= 2'b00;
    else
      estado_presente <= proximo_estado;
  end

  always_comb begin:
    case (estado_presente)
      2'b00: begin
        saida = 1'b0;
        if(entrada) 
          proximo_estado = 2'b01;
      end
      2'b01: begin
        saida = 1'b1;
        if(entrada) 
          proximo_estado = 2'b10;
      end
      2'b10: begin
        saida = 1'b0;
        if(entrada) 
          proximo_estado = 2'b11;
      end
      2'b11: begin
        saida = 1'b1;
        if(entrada) 
          proximo_estado = 2'b00;
      end
    endcase
  end

endmodule
