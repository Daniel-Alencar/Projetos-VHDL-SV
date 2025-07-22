module bmp280_ctrl #(parameter DATA_BITS=8)(
  // uart_ready_in: Indica se o UART está preparado para fazer uma transmissão
  // uart_valid_in: Indica de o receptor do UART recebeu um dado válido
  // spi_ready_in: Indica se o SPI está pronto para a transferência de informações
  // spi_valid_in: Indica se o modo SPI concluiu esta transferência
  input clk, n_rst, uart_ready_in, uart_valid_in, spi_ready_in, spi_valid_in,

  // Byte recebido por meio da UART
  // Byte recebido por meio da SPI
  input [DATA_BITS-1:0] uart_data_in, spi_data_in,

  // tied_SS: Indica se o SS deve ficar ativo durante uma transferência 
  // consecutiva de palavras
  // spi_en: Habilitação da comunicação SPI
  // uart_en: Habilitação da comunicação UART
  output tied_SS, spi_en, uart_en,

  // Bytes recebidos da UART e do SPI
  output [DATA_BITS-1:0] uart_data_out, spi_data_out,
  // Indica a quantidade de palavras sequenciais que são necessárias 
  output [5:0] spi_data_words
);

  // Declaração dos estados simbólicos
  localparam [4:0]
  // Repouso
  idle = 0,
  // Endereço de identificação do sensor
  add_id = 1,
  // Valor de identificação do sensor
  rd_id = 2,
  // Endereço do status do sensor
  add_status = 3,
  // Leitura do status do sensor
  rd_status = 4,
  // Endereço de controle da medição
  add_ctrl_meas = 5,
  // Escrita do controle da medição 
  wr_ctrl_meas = 6,
  // Endereço da configuração
  add_config = 7,
  // Escrita da configuração
  wr_config = 8,
  // Endereço da informação da pressão (byte mais significativo)
  add_press_msb = 9,
  // Valor da informação da pressão (byte mais significativo)
  rd_press_msb = 10,
  // Endereço da informação da pressão (byte menos significativo)
  add_press_lsb = 11,
  // Valor da informação da pressão (byte menos significativo)
  rd_press_lsb = 12,
  // Endereço da informação da pressão (últimos 4 bits)
  add_press_xlsb = 13,
  // Valor da informação da pressão (últimos 4 bits)
  rd_press_xlsb = 14,
  // Endereço da informação da pressão (byte mais significativo)
  add_temp_msb = 15,
  // Valor da informação da temperatura (byte mais significativo)
  rd_temp_msb = 16,
  // Endereço da informação da temperatura (byte menos significativo)
  add_temp_lsb = 17,
  // Valor da informação da temperatura (byte menos significativo)
  rd_temp_lsb = 18,
  // Endereço da informação da temperatura (últimos 4 bits)
  add_temp_xlsb = 19,
  // Valor da informação da temperatura (últimos 4 bits)
  rd_temp_xlsb = 20;

  // Declaração dos sinais

  // Informa o estado do controlador BMP280
  reg[4:0] state, next_state;
  // Contagem das palavras sequenciais transmitidas pelo SPI
  reg[5:0] word_cnt, next_word;
  // Indica quantas palavras sequenciais o SPI quer que execute
  reg[5:0] data_words_reg, next_data_words;
  // Dados a serem transmitidos por meio do SPI  
  reg[DATA_BITS-1:0] spi_data_reg, next_spi_data;
  // Dados a serem transmitidos por meio do UART  
  reg[DATA_BITS-1:0] uart_data_reg, next_uart_data;
  // O seletor de escrevos deve permanecer ativo durante a transmissão sequencial
  reg tied_SS_reg, next_tied_SS;
  // Habilitação SPI 
  reg spi_en_reg, next_spi_en;
  // Habilitação UART
  reg uart_en_reg, next_uart_en;

  // Registradores da máquina de estados para o controlador BMP280
  always @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
      state <= idle;
      word_cnt <= 0;
      data_words_reg <= 0;
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