`timescale 1ns/1ps

module tb_design_1;

    reg dev_clk = 0;
    reg rx = 1; // UART idle

    // I2C lines
    wire SCL;
    wire SDA;

    // UART TX
    wire tx;

    // Instancia o DUT
    design_1_wrapper dut (
        .SCL(SCL),
        .SDA(SDA),
        .dev_clk(dev_clk),
        .rx(rx),
        .tx(tx)
    );

    // Clock de 25 MHz
    always #20 dev_clk = ~dev_clk;

    // --- Escravo I2C simulado ---
    reg SDA_slave = 1; // inicializa em alta
    assign SDA = SDA_slave ? 1'bz : 1'b0;

    localparam [6:0] SLAVE_ADDR = 7'h68;

    reg [7:0] tx_data [0:3]; // bytes que o escravo vai enviar
    integer i, bit_cnt;

    initial begin
        tx_data[0] = 8'h75;
        tx_data[1] = 8'h00;
        tx_data[2] = 8'h01;
        tx_data[3] = 8'h02;
        SDA_slave = 1; 
        #1000; // espera 1 us

        forever begin
            @(negedge SCL); // escravo só reage no flanco de descida de SCL

            // START condition detection
            if (SDA === 0 && SCL === 1) begin
                // Espera endereço + R/W
                bit_cnt = 0;
                while(bit_cnt < 8) begin
                    @(negedge SCL);
                    bit_cnt = bit_cnt + 1;
                end

                // Envia ACK
                @(negedge SCL);
                SDA_slave = 0;
                @(posedge SCL);
                SDA_slave = 1;

                // Envia bytes se master pediu leitura
                for (i = 0; i < 4; i = i+1) begin
                    for (bit_cnt = 7; bit_cnt >= 0; bit_cnt = bit_cnt - 1) begin
                        @(negedge SCL);
                        SDA_slave = tx_data[i][bit_cnt];
                    end
                    // Libera SDA para o master enviar ACK/NACK
                    @(negedge SCL);
                    SDA_slave = 1'bz;
                    @(posedge SCL);
                end
            end
        end
    end

    // --- Simulação e dump de waveform ---
    initial begin
        $dumpfile("tb_design_1.vcd");
        $dumpvars(0, tb_design_1);
        #500_000; // simula 500 us
        $display("Simulação finalizada");
        $finish;
    end

endmodule
