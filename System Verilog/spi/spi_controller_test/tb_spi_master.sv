`timescale 1ns / 1ps

module tb_spi_master;

  // Parâmetros
  parameter DATA_BITS = 8;
  parameter BRDV = 2;

  // Clock e reset
  reg clk = 0, n_rst = 0;
  always #5 clk = ~clk;

  // Entradas do SPI master
  reg spi_en;
  reg tied_SS;
  reg MISO;
  reg [DATA_BITS-1:0] data_in;
  reg [5:0] data_words;

  // Saídas do SPI master
  wire SCK, SS, MOSI;
  wire ready_out, valid_out;
  wire [DATA_BITS-1:0] data_out;

  // Memória TX e RX como arrays para facilitar manipulação
  reg [DATA_BITS-1:0] tx_data [0:3];
  reg [DATA_BITS-1:0] rx_data [0:3];

  // Dados do escravo SPI
  reg [DATA_BITS-1:0] slave_data [0:3];
  reg [DATA_BITS-1:0] slave_shift;
  
  integer i;

  // Geração do MISO (dado válido na borda correta)
  // Como CPHA=1, dados são amostrados na borda de subida, então
  // alinhamos MISO na borda de subida do SCK para evitar glitches
  always @(posedge SCK or posedge SS) begin
    if (SS) begin
      // SS alto: reinicia o shift
      slave_shift <= 0;
      // linha inativa (pode ser 1'b0 também)
      MISO <= 1'bz; 
    end else begin
      MISO <= slave_shift[7];
      slave_shift <= {slave_shift[6:0], 1'b0};
    end
  end

  // Instanciação do módulo SPI master
  spi_master #(
    .DATA_BITS(DATA_BITS),
    .CPOL(0),
    .CPHA(1),
    .BRDV(BRDV),
    .LSBF(0)
  ) uut (
    .clk(clk),
    .n_rst(n_rst),
    .spi_en(spi_en),
    .tied_SS(tied_SS),
    .MISO(MISO),
    .data_in(data_in),
    .data_words(data_words),
    .SCK(SCK),
    .SS(SS),
    .MOSI(MOSI),
    .ready_out(ready_out),
    .valid_out(valid_out),
    .data_out(data_out)
  );

  initial begin
    $display("Início da simulação SPI Master");
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_spi_master);

    // Inicializa valores
    spi_en = 0;
    data_in = 0;
    data_words = 4;
    tied_SS = 1'b1;
    MISO = 1'bz;

    tx_data[0] = 8'hFA;
    tx_data[1] = 8'hFB;
    tx_data[2] = 8'hFC;
    tx_data[3] = 8'hFE;

    slave_data[0] = 8'hAA;
    slave_data[1] = 8'hBB;
    slave_data[2] = 8'hCC;
    slave_data[3] = 8'hDD;

    // Reset ativo
    n_rst = 0;
    #20;
    n_rst = 1;

    #20;

    // Mantém SS ativo durante todas as transmissões para testar 'tied_SS'
    tied_SS = 0; 

    // Loop de transmissão das 4 palavras
    for (i = 0; i < 4; i = i + 1) begin
      wait (ready_out == 1);
      data_in = tx_data[i];
      slave_shift = slave_data[i];

      spi_en = 1;
      #10;
      spi_en = 0;

      wait (valid_out == 1);
      rx_data[i] = data_out;
      $display("TX[%0d] = %h | RX[%0d] = %h", i, tx_data[i], i, rx_data[i]);
      #10;
    end

    // Desativa SS após transmissões
    tied_SS = 1;

    #20;
    $display("Fim da transmissão SPI");
    $finish;
  end

endmodule
