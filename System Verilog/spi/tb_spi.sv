`timescale 1ns / 1ps

module tb_spi;

  // Parâmetros de configuração
  localparam DATA_BITS = 8;
  localparam CPOL = 0;
  localparam CPHA = 1;
  localparam BRDV = 4;
  localparam LSBF = 0;

  // Sinais
  logic clk, n_rst;
  logic spi_enable;
  logic MISO;
  logic [DATA_BITS-1:0] data_in;
  logic SCK, SS, MOSI, ready_out, valid_out;
  logic [DATA_BITS-1:0] data_out;
  logic [DATA_BITS-1:0] miso_data;

  // Instancia o módulo SPI
  spi #(
    .DATA_BITS(DATA_BITS),
    .CPOL(CPOL),
    .CPHA(CPHA),
    .BRDV(BRDV),
    .LSBF(LSBF)
  ) dut (
    .clk(clk),
    .n_rst(n_rst),
    .spi_enable(spi_enable),
    .MISO(MISO),
    .data_in(data_in),
    .SCK(SCK),
    .SS(SS),
    .MOSI(MOSI),
    .ready_out(ready_out),
    .valid_out(valid_out),
    .data_out(data_out)
  );

  // Clock de 100 MHz (período = 10ns)
  always #5 clk = ~clk;

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_spi);

    // Inicializa sinais
    clk = 0;
    n_rst = 0;
    spi_enable = 0;
    
    // Dado a ser transmitido pelo mestre (MOSI)
    data_in = 8'b10101010; 
    MISO = 0;

    // Reset
    #20;
    n_rst = 1;

    // Aguarda o SPI estar pronto
    @(posedge ready_out);

    // Inicia a transação
    spi_enable = 1;
    @(posedge clk);
    spi_enable = 0;

    // Aguarda início da transação SPI
    wait (SS == 0);

    // Dado que será recebido do escravo pelo MISO
    miso_data = 8'b11001100;

    // Envia bit a bit do MISO sincronizado com SCK
    for (int i = 0; i < DATA_BITS; i++) begin
      // Borda de descida do clock SPI
      @(negedge SCK);
      if (LSBF)
        MISO = miso_data[i];
      else
        MISO = miso_data[DATA_BITS - 1 - i];
    end

    // Aguarda finalização e dados válidos
    wait (valid_out);

    // Mostra o resultado
    $display("Recebido via SPI: %b", data_out);
    if (data_out === miso_data)
      $display("SUCESSO: Dados recebidos corretamente!");
    else
      $display("ERRO: Dados incorretos!");

    #5000;
    $finish;
  end

endmodule