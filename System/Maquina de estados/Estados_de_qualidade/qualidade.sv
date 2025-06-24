module qualidade (
  input logic clk, n_rst, presenca, rgb, rgb_valido,
  // Representando os estados do led verde e vermelho
  output logic [1:0] leds
);

  typedef enum { repouso, avaliacao, avaliado } tipo_estado;

  tipo_estado estado_presente = repouso;
  tipo_estado proximo_estado = repouso;

  always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst)
      estado_presente <= repouso;
    else
      estado_presente <= proximo_estado;
  end

  always_comb begin
    case(estado_presente)
      repouso: begin
        leds = 2'b00;
        if(presenca) proximo_estado = avaliacao;
      end
      avaliacao: begin
        if(rgb_valido) begin
          if(rgb)
            // O led verde acende
            leds = 2'b01;
          else 
            // O led vermelho acende
            leds = 2'b10;
          
          proximo_estado = avaliado;
        end
      end
      avaliado: begin
        leds = 2'b11;
        if(~presenca) proximo_estado = repouso;
      end
    endcase
  end
endmodule