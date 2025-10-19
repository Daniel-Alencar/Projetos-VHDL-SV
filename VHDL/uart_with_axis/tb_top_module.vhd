library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================================
-- Testbench do top_module
-- - Testa a recepção de 1 byte UART (8N1)
-- - Clock = 50 MHz
-- - Baud rate = 115200 bps  -> período do bit ≈ 8,68 µs
-- ============================================================================

entity tb_top_module is
end tb_top_module;

architecture tb of tb_top_module is

  -- Constantes de simulação
  constant CLK_FREQ  : integer := 50_000_000;
  constant CLK_PERIOD: time := 20 ns;          -- 50 MHz
  constant BAUD_RATE : integer := 115200;
  constant BIT_PERIOD: time := 1 sec / BAUD_RATE;  -- ~8.68 us

  -- Sinais de interconexão
  signal clk         : std_logic := '0';
  signal reset_n     : std_logic := '0';
  signal rx          : std_logic := '1';  -- linha serial idle = '1'
  signal data_out    : std_logic_vector(7 downto 0);
  signal data_ready  : std_logic;
  signal frame_error : std_logic;
  signal busy        : std_logic;

begin

  ---------------------------------------------------------------------------
  -- Geração do clock de 50 MHz
  ---------------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  ---------------------------------------------------------------------------
  -- Instancia o módulo top_module sob teste (UUT)
  ---------------------------------------------------------------------------
  uut : entity work.top_module
    port map (
      clk         => clk,
      reset_n     => reset_n,
      rx          => rx,
      data_out    => data_out,
      data_ready  => data_ready,
      frame_error => frame_error,
      busy        => busy
    );

  ---------------------------------------------------------------------------
  -- Processo de estímulo
  -- Envia um byte serial "01010101" (0x55) no formato UART (8N1)
  ---------------------------------------------------------------------------
  stim_proc : process
    procedure send_byte(signal rx_line : out std_logic; data : std_logic_vector(7 downto 0)) is
    begin
      -- Start bit (nível baixo)
      rx_line <= '0';
      wait for BIT_PERIOD;

      -- Bits de dados (LSB primeiro)
      for i in 0 to 7 loop
        rx_line <= data(i);
        wait for BIT_PERIOD;
      end loop;

      -- Stop bit (nível alto)
      rx_line <= '1';
      wait for BIT_PERIOD;
    end procedure;

    begin

      -- Reset inicial
      reset_n <= '0';
      wait for 100 ns;
      reset_n <= '1';
      wait for 100 us;

      report "=== Iniciando transmissão UART de teste ===";

      -- Envia o byte 0x55 = "01010101"
      send_byte(rx, "10101010");

      -- Espera tempo suficiente para recepção
      wait for 20 * BIT_PERIOD;

      if data_ready = '1' then
        report "Byte recebido: " & integer'image(to_integer(unsigned(data_out)));
      else
        report "Nenhum byte recebido (erro de sincronismo?)" severity warning;
      end if;

      report "Fim da simulação.";
      wait;
    end process;

end tb;
