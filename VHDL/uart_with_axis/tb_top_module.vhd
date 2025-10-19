library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================================
-- Testbench do top_module
-- - Testa recepção UART com suporte a paridade e 1 ou 2 bits de parada
-- - Clock = 50 MHz, Baud = 115200 bps
-- - Simula envio do byte 0x55 ("01010101")
-- ============================================================================

entity tb_top_module is
end tb_top_module;

architecture tb of tb_top_module is

  ---------------------------------------------------------------------------
  -- Constantes de simulação
  ---------------------------------------------------------------------------
  constant CLK_FREQ   : integer := 50_000_000;
  constant CLK_PERIOD : time := 20 ns;                     -- 50 MHz
  constant BAUD_RATE  : integer := 115200;
  constant BIT_PERIOD : time := 1 sec / BAUD_RATE;         -- ≈ 8.68 µs

  constant PARITY_MODE : string := "EVEN";  -- "NONE", "EVEN" ou "ODD"
  constant STOP_BITS   : integer := 1;      -- 1 ou 2 bits de parada

  ---------------------------------------------------------------------------
  -- Sinais de interconexão
  ---------------------------------------------------------------------------
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
  -- Processo de estímulo: envia bytes UART simulando a linha "rx"
  ---------------------------------------------------------------------------
  stim_proc : process
    -- Função auxiliar: calcula paridade de um vetor de bits
    function calc_parity(
      data   : std_logic_vector;
      mode   : string
    ) return std_logic is
      variable ones : integer := 0;
    begin
      for i in data'range loop
        if data(i) = '1' then
          ones := ones + 1;
        end if;
      end loop;

      if mode = "EVEN" then
        if (ones mod 2) = 0 then
          return '0';  -- já par
        else
          return '1';
        end if;
      elsif mode = "ODD" then
        if (ones mod 2) = 0 then
          return '1';
        else
          return '0';
        end if;
      else
        return '0';  -- "NONE": valor irrelevante
      end if;
    end function;

    -- Procedimento que envia um byte via linha RX (formato UART)
    procedure send_byte(
      signal rx_line : out std_logic;
      data           : std_logic_vector(7 downto 0);
      parity_mode    : string;
      stop_bits      : integer
    ) is
      variable parity_bit : std_logic;
    begin
      parity_bit := calc_parity(data, parity_mode);

      -- Start bit (nível baixo)
      rx_line <= '0';
      wait for BIT_PERIOD;

      -- Bits de dados (LSB primeiro)
      for i in 0 to 7 loop
        rx_line <= data(i);
        wait for BIT_PERIOD;
      end loop;

      -- Bit de paridade (se aplicável)
      if parity_mode /= "NONE" then
        rx_line <= parity_bit;
        wait for BIT_PERIOD;
      end if;

      -- Bits de parada (nível alto)
      rx_line <= '1';
      for i in 1 to stop_bits loop
        wait for BIT_PERIOD;
      end loop;
    end procedure;

  begin
    -----------------------------------------------------------------------
    -- RESET inicial
    -----------------------------------------------------------------------
    reset_n <= '0';
    wait for 100 ns;
    reset_n <= '1';
    wait for 100 us;

    report "=== Iniciando transmissão UART de teste ===";

    -----------------------------------------------------------------------
    -- Envia o byte 0x55 (01010101)
    -----------------------------------------------------------------------
    send_byte(rx, "10101010", PARITY_MODE, STOP_BITS);

    wait for 20 * BIT_PERIOD;

    -----------------------------------------------------------------------
    -- Resultados
    -----------------------------------------------------------------------

    if frame_error = '1' then
      report "Frame error detectado!" severity warning;
    end if;

    report "Fim da simulação.";
    wait;
  end process;

end tb;
