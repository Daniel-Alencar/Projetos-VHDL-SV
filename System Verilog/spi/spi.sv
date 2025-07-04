// Esses parâmetros tornam o módulo flexível:
// DATA_BITS: Quantidade de bits transmitidos por transação (tamanho dos dados).
// CPOL (Clock Polarity): Polaridade do clock em repouso.
//     0 → SCK em nível baixo quando ocioso.
//     1 → SCK em nível alto quando ocioso.
// CPHA (Clock Phase): Fase de amostragem dos dados.
//     0 → MISO é lido na borda ativa (primeira transição).
//     1 → MISO é lido na borda inativa (segunda transição).
// BRDV: Divisor de clock → determina a frequência de SCK.
// LSBF: LSB First.
//     0 → MSB (bit mais significativo) primeiro.
//     1 → LSB (bit menos significativo) primeiro.

module spi #(parameter DATA_BITS=8, CPOL=0, CPHA=1, BRDV=2, LSBF=0)(
  input clk, n_rst, spi_enable, MISO,
  input [DATA_BITS-1:0] data_in,

  // ready_out: Indica que o SPI está pronto para uma nova transação
  // valid_out: Indica que data_out contém dados válidos.
  output SCK, SS, MOSI, ready_out, valid_out,
  output [DATA_BITS-1:0] data_out
);

  // Declaração dos estados simbólicos
  localparam [1:0]
  idle = 2'b00,
  data = 2'b01,
  trail = 2'b10;

  // idle: Espera por spi_enable.
  // data: Transmissão/recepção de bits.
  // trail: Encerramento da transação (delay final com SCK e SS).

  reg [1:0] state, next_state;
  reg [7:0] clk_cnt, next_clk; // 8 bits, considerando BRDV_max = 256
  reg [4:0] bit_cnt, next_bit; // 5 bits, considerando DATA_BITS_max = 32 bits
  reg SCK_reg, next_SCK;
  reg SS_reg, next_SS;
  reg [DATA_BITS-1:0] spi_data_reg, next_spi_data;
  reg MISO_reg;
  reg ready_reg, next_ready;
  reg valid_reg, next_valid;

  // Registradores da máquina de estados para o módulo SPI
  always_ff @(posedge clk, negedge n_rst) begin
      if (~n_rst) begin
          state <= idle;
          clk_cnt <= 0;
          bit_cnt <= 0;
          SCK_reg <= CPOL;
          SS_reg <= 1'b1;
          spi_data_reg <= '0;
          ready_reg <= 1'b0;
          valid_reg <= 1'b0;
      end
      else begin
          state <= next_state;
          clk_cnt <= next_clk;
          bit_cnt <= next_bit;
          SCK_reg <= next_SCK;
          spi_data_reg <= next_spi_data;
          SS_reg <= next_SS;
          ready_reg <= next_ready;
          valid_reg <= next_valid;
      end
  end

  // Lógica combinacional para a transição entre estados
  always_comb begin    
      next_state = state;
      next_clk = clk_cnt;
      next_bit = bit_cnt;
      case (state)
      idle: begin
          if (spi_enable) begin
              next_clk = 0;
              bit_cnt = 0;
              next_state = data;
          end
      end
      data: begin
          if (clk_cnt == BRDV-1) begin
              next_clk = 0;
              if (bit_cnt == DATA_BITS)
                next_state = trail;
              else
                next_bit = bit_cnt + 1;
          end
          else
            next_clk = clk_cnt + 1;
      end
      trail: begin
          if (clk_cnt == (BRDV/2)-1)
            next_state = idle;
          else
            next_clk = clk_cnt + 1;
      end
      endcase
  end

  // Lógica combinacional para o clock serial
  always_comb begin
      next_SCK = SCK_reg;
      case (state)
      idle: 
        next_SCK = CPOL;
      data: begin
          if (clk_cnt == (BRDV/2)-1 || clk_cnt == BRDV-1)
            next_SCK = ~SCK_reg;
      end
      trail: 
        next_SCK = SCK_reg;
      endcase
  end

  // Lógica combinacional para os registradores de dados 
  // e para os sinais ready_out, valid_out e SS
  always @* begin
      next_SS = SS_reg;
      next_spi_data = spi_data_reg;
      next_ready = ready_reg;
      next_valid = valid_reg;
      case (state)
      idle: begin
          next_ready = 1'b1;
          next_valid = 1'b0;
          if (spi_enable) begin
              next_SS = 1'b0;
              next_spi_data = data_in;
          end
      end
      data: begin
          next_ready = 1'b0;

          // Amostragem do MISO na primeira borda (para CPHA = 0)
          if (clk_cnt == 0 && CPHA == 0) begin
              MISO_reg = MISO;
          end

          // Amostragem de MISO em CPHA = 1, após a primeira transição
          if (clk_cnt == (BRDV/2)-1) begin
              if (CPHA == 0) begin
                  // segunda amostragem (para os demais bits)
                  MISO_reg = MISO;
              end else if (CPHA == 1 && bit_cnt > 0) begin
                  if (LSBF == 0)
                      next_spi_data = {spi_data_reg[DATA_BITS-2:0], MISO_reg};
                  else
                      next_spi_data = {MISO_reg, spi_data_reg[DATA_BITS-1:1]};
              end
          end

          // Envio de MISO_reg para data_out no final do ciclo
          if (clk_cnt == BRDV-1) begin
              if (CPHA == 0) begin
                  next_valid = 1'b1;
                  if (LSBF == 0)
                      next_spi_data = {spi_data_reg[DATA_BITS-2:0], MISO_reg};
                  else
                      next_spi_data = {MISO_reg, spi_data_reg[DATA_BITS-1:1]};
              end else begin
                  MISO_reg = MISO;
              end
          end
      end
      trail: begin
          if (clk_cnt == (BRDV/2)-1) begin
              next_SS = 1'b1;
              if (CPHA == 1) begin
                  next_valid = 1'b1;
                  if (LSBF == 0)
                  next_spi_data = {spi_data_reg[DATA_BITS-2:0], MISO_reg};
                  else
                  next_spi_data = {MISO_reg, spi_data_reg[DATA_BITS-1:1]};
              end
          end
      end
      endcase
  end

  // Direcionamento dos registrasdores para as saídas
  assign SCK = SCK_reg;
  assign data_out = spi_data_reg;
  assign SS = SS_reg;
  assign MOSI = LSBF == 0 ? spi_data_reg[DATA_BITS-1] : spi_data_reg[0];
  assign ready_out = ready_reg;
  assign valid_out = valid_reg;

endmodule