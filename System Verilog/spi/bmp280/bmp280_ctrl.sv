module bmp280_ctrl #(parameter DATA_BITS=8)(
  input clk, n_rst, uart_ready_in, uart_valid_in, spi_ready_in, spi_valid_in,
  input [DATA_BITS-1:0] uart_data_in, spi_data_in,
  output tied_SS, spi_en, uart_en,
  output [DATA_BITS-1:0] uart_data_out, spi_data_out,
  output [5:0] spi_data_words
);

  // Declaração dos estados simbólicos
  localparam [4:0]
  // Repouso
  idle = 0,
  // Endereço dos valores
  add_id = 1,
  // Leitura dos valores
  rd_id = 1,
  // Endereço do status do sensor
  add_status
  // Leitura do status do sensor
  rd_status
  // Endereço de controle de medidas
  add_ctrl_meas
  // Escrita do controle de medidas
  wr_ctrl_meas
  // Endereço da configuração
  add_config
  // Escrita da configuração
  wr_config
  // 
  add_press_msb
  // 
  rd_press_lsb
  // 
  add_press_xlsb
  //
  rd_press_xlsb
  //
  add_temp_msb
  //
  add_temp_lsb
  //
  rd_temp_lsb
  //
  add_temp_xlsb
  //
  rd_temp_xlsb

  // Declaração dos sinais
  reg[4:0] state, next_state;
  reg[5:0] word_cnt, next_word;
  reg[5:0] data_words_reg, next_data_words;
  reg[DATA_BITS-1:0] spi_data_reg, next_spi_data;
  reg[DATA_BITS-1:0] uart_data_reg, next_uart_data;
  reg tied_SS_reg, next_tied_SS;
  reg spi_en_reg, next_spi_en;
  reg uart_en_reg, next_uart_en;

  // Registradores
  always @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
      state <= idle;
      word_cnt <= 0;
      data_word_cnt <= 0;
      spi_data_reg <= '0;
      uart_data_reg <= '0;
      tied_SS <= 1'b0;
      spi_en_reg <= 1'b0;
      uart_en_reg <= 1'b0;
    end
    else begin
      state <= next_state;
      word_cnt <= next_word;
      data_words_reg <= next_data_words;
      spi_data_reg <= next_spi_data;
      uart_data_reg <= next_uart_data;
      tied_SS_reg <= next_tied_SS;
      spi_en_reg <= next_spi_en;
      uart_en_reg <= next_uart_en;
    end
  end

  // Lógica combinacional da máquina de estados para o controlador bmp280
  always @(*) begin
    next_state = state;
    next_word = word_cnt;
    next_data_words = data_words_reg;
    next_spi_data = spi_data_reg;
    next_uart_data = uart_data_reg;
    next_tied_SS = tied_SS_reg;
    next_spi_en = spi_en_reg;
    next_uart_en = uart_en_reg;

    case (state)
      idle: begin
        next_uart_en = 1'b0;
        next_tied_SS = 1'b0;

        if(uart_valid_in && uart_data_in == "m") begin
          next_state = add_in;
        end
      end
      add_in: begin
        if(spi_ready_in && uart_ready_in) begin
          next_tied_SS = 1'b1;
          next_data_words = 2;
          next_spi_data = 8'hD0;
          next_spi_en = 1'b1;
          word_cnt = 0;
          next_state = rd_id;
        end
      end
      rd_in: begin
        next_spi_en = 1'b0;
        if(word_cnt == 2) begin
          next_uart_en = 1'b0;
          if()
        end
      end
      add_status: begin
        next_uart_en = 1'b0;
        if(spi_ready_in && uart_ready_in) begin
          next_data_words
        end
      end
    endcase
  end

endmodule