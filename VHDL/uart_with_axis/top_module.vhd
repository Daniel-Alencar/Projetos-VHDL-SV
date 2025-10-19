library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================================
-- Top-level temporário de teste
-- Contém apenas:
--   - baud_gen   : gera pulso "baud_tick" a partir de clk e taxa de baud
--   - uart_rx    : receptor UART que usa o baud_tick
--
-- Conexões externas:
--   clk, reset_n, rx
-- Saídas de teste:
--   data_out, data_ready, frame_error, busy
-- ============================================================================

entity top_module is
  port (
    clk         : in  std_logic;                      -- Clock principal (ex.: 50 MHz)
    reset_n     : in  std_logic;                      -- Reset ativo em nível baixo
    rx          : in  std_logic;                      -- Linha serial RX (do PC / USB-UART)
    data_out    : out std_logic_vector(7 downto 0);   -- Byte recebido
    data_ready  : out std_logic;                      -- Pulso: dado pronto
    frame_error : out std_logic;                      -- Bit de stop inválido
    busy        : out std_logic                       -- UART está ocupada recebendo
  );
end top_module;

architecture rtl of top_module is

  ---------------------------------------------------------------------------
  -- Sinal interno de ligação entre baud_gen e uart_rx
  ---------------------------------------------------------------------------
  signal baud_tick : std_logic;

begin

  ---------------------------------------------------------------------------
  -- Instância do gerador de baud rate
  -- Divide o clock de 50 MHz para gerar pulsos na frequência de 115200 baud
  ---------------------------------------------------------------------------
  baud_gen_inst : entity work.baud_gen
    generic map (
      CLK_FREQ  => 50_000_000,  -- Clock principal em Hz
      BAUD_RATE => 115200       -- Taxa de baud desejada
    )
    port map (
      clk       => clk,
      reset_n   => reset_n,
      baud_tick => baud_tick    -- Saída: pulso de amostragem por bit
    );

  ---------------------------------------------------------------------------
  -- Instância do receptor UART
  -- Recebe dados seriais em "rx" e produz bytes paralelos "data_out"
  ---------------------------------------------------------------------------
  uart_rx_inst : entity work.uart_rx
    generic map (
      DATA_BITS => 8,   -- 8 bits de dados
      STOP_BITS => 1,   -- 1 bit de parada
      PARITY => "EVEN"  -- Sem paridade
    )
    port map (
      clk         => clk,
      reset_n     => reset_n,
      rx          => rx,
      baud_tick   => baud_tick,
      data_out    => data_out,
      data_ready  => data_ready,
      frame_error => frame_error,
      busy        => busy
    );

end rtl;
