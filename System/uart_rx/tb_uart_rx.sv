`timescale 1ns / 1ps
`include "uart_rx.sv"

module uart_rx_tb;

    // Sinais de entrada
    logic clk;
    logic n_rst;
    logic rx;

    // Sinais de saída
    logic ready_out, valid_out;
    byte data_out;

    uart_rx uut (
        .clk(clk),
        .n_rst(n_rst),
        .rx(rx),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    // Geração de clock
    always #5 clk = ~clk;

    // Tarefa para transmitir 1 byte
    task send_uart_byte(input byte data);
        integer i;
        begin
            // Start bit (0)
            rx = 0;
            #(16 * 10);

            // Bits de dados (LSB first)
            for (i = 0; i < 8; i++) begin
                rx = data[i];
                #(16 * 10);
            end

            // Stop bit (1)
            rx = 1;
            #(16 * 10);
        end
    endtask

    initial begin
        // Inicialização
        clk = 0;
        rx = 1;
        n_rst = 0;

        // Geração do arquivo VCD para GTKWave
        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, uart_rx_tb);

        // Monitoramento em console
        $monitor("Time: %0t | rx: %b | valid_out: %b | ready_out: %b | data_out: %h", $time, rx, valid_out, ready_out, data_out);

        // Solta o reset após 20 ns
        #20;
        n_rst = 1;

        // Aguarda ficar pronto
        wait (ready_out == 1);
        #20;

        // Envia byte 0xA5
        $display("Sending 0xA5...");
        send_uart_byte(8'hA5);

        // Aguarda sinal de dado válido
        wait (valid_out == 1);
        #10;

        // Verifica valor recebido
        if (data_out == 8'hA5)
            $display("SUCCESS: Received 0x%0h", data_out);
        else
            $display("ERROR: Expected 0xA5 but got 0x%0h", data_out);

        // Aguarda voltar ao idle
        wait (ready_out == 1);
        #100;

        $finish;
    end

endmodule
