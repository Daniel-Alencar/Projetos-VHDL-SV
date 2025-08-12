`timescale 1ns/1ps

module tb_spi_controller;

    // Parâmetros
    parameter DATA_BITS = 8;

    // Sinais de teste
    reg clk;
    reg n_rst;
    reg spi_en;
    reg MISO;
    reg [DATA_BITS-1:0] data_in;
    wire SCK, SS, MOSI, ready_out, valid_out;
    wire [DATA_BITS-1:0] data_out;

    // Armazenamento dos dados TX e RX
    reg [DATA_BITS-1:0] tx_data [0:3];
    reg [DATA_BITS-1:0] rx_data [0:3];
    integer i;

    // Instância do DUT
    spi_controller #(DATA_BITS) uut (
        .clk(clk),
        .n_rst(n_rst),
        .spi_en(spi_en),
        .MISO(MISO),
        .data_in(data_in),
        .SCK(SCK),
        .SS(SS),
        .MOSI(MOSI),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    // Geração de clock (100 MHz)
    always #5 clk = ~clk;

    // Escravo SPI simples — responde com dado fixo para teste
    reg [DATA_BITS-1:0] slave_shift;
    reg [3:0] bit_cnt;

    always @(negedge SS) begin
        // Quando o mestre abaixa SS, prepara dado para enviar
        // exemplo fixo; poderia ser baseado no MOSI
        slave_shift <= 8'hA5; 
        bit_cnt <= DATA_BITS;
    end

    always @(negedge SCK) begin
        if (!SS) begin
            MISO <= slave_shift[DATA_BITS-1];
            slave_shift <= {slave_shift[DATA_BITS-2:0], 1'b0};
        end else begin
            MISO <= 1'b0;
        end
    end

    // Procedimento de teste
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_spi_controller);
            
        // Inicialização
        clk = 0;
        n_rst = 0;
        spi_en = 0;
        MISO = 0;
        data_in = 0;
        #20;
        n_rst = 1;

        // Carregar dados a transmitir
        tx_data[0] = 8'hFA;
        tx_data[1] = 8'hFB;
        tx_data[2] = 8'hFC;
        tx_data[3] = 8'hFE;

        // Loop de transmissão/recepção
        for (i = 0; i < 4; i = i + 1) begin
            // Espera mestre estar pronto
            @(posedge clk);
            wait (ready_out);
            data_in = tx_data[i];
            spi_en = 1;
            @(posedge clk);
            spi_en = 0;

            // Espera recepção completa
            wait (valid_out);
            rx_data[i] = data_out;
            $display("Transmissão %0d: TX=%h  RX=%h", i, tx_data[i], rx_data[i]);
        end

        $display("Teste concluído.");
        $stop;
    end

endmodule
