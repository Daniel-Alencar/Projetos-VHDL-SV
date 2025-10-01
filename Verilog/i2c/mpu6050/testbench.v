`timescale 1ns / 1ps

module tb_design_1_wrapper;

  // sinais do DUT
  reg dev_clk;
  reg rx;
  wire tx;
  wire SCL;
  wire SDA;

  // ===============================
  // Instancia do DUT
  // ===============================
  design_1_wrapper uut (
    .SCL(SCL),
    .SDA(SDA),
    .dev_clk(dev_clk),
    .rx(rx),
    .tx(tx)
  );

  // ===============================
  // Clock 25 MHz
  // ===============================
  initial begin
    dev_clk = 0;
    // 25 MHz -> período 40 ns
    forever #20 dev_clk = ~dev_clk; 
  end

  // ===============================
  // UART RX simulado
  // ===============================
  initial begin
    rx = 1'b1; // idle
    #1000;
    // Exemplo: enviar um byte 'A' (0x41) no UART 115200 bps
    // Cada bit dura ~8680 ns (1/115200 s)
    uart_send_byte(8'h41);
  end

  // ===============================
  // Tarefa para enviar byte via UART
  // ===============================
  task uart_send_byte(input [7:0] data);
    integer i;
    begin
      // start bit
      rx = 1'b0;
      #(8680);
      // 8 bits de dados, LSB primeiro
      for (i = 0; i < 8; i = i + 1) begin
        rx = data[i];
        #(8680);
      end
      // stop bit
      rx = 1'b1;
      #(8680);
    end
  endtask

  // ===============================
  // Modelo simplificado de I2C MPU6050 (open-drain)
  // ===============================
  reg sda_out;
  // open-drain
  assign SDA = sda_out ? 1'bz : 1'b0;
  initial begin
    // libera SDA
    sda_out = 1'b1; 
  end

  // ===============================
  // Dump para simulação
  // ===============================
  initial begin
    $dumpfile("tb_design_1_wrapper.vcd");
    $dumpvars(0, tb_design_1_wrapper);
  end

  // ===============================
  // Tempo de simulação
  // ===============================
  initial begin
    #500000000000;
    $finish;
  end

endmodule
