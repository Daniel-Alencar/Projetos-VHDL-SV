library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================================
-- Top-level temporário de teste
--
-- Contém:
--   - baud_gen : gera pulso "baud_tick" a partir de clk e taxa de baud
--   - uart_rx  : receptor UART que converte o sinal serial RX em AXIS
--   - fifo_tx  : FIFO que armazena bytes vindos do UART via interface AXIS
--
-- Conexões externas:
--   clk, reset_n, rx
--
-- Saídas de teste:
--   axis_tdata, axis_tvalid, frame_error, parity_error, busy
-- ============================================================================

entity top_module is
  port (
    clk          : in  std_logic;                      -- Clock principal (ex.: 50 MHz)
    reset_n      : in  std_logic;                      -- Reset ativo em nível baixo
    rx           : in  std_logic;                      -- Linha serial RX (do PC / USB-UART)

    -- Saídas de depuração (vindas da saída do FIFO)
    axis_tdata   : out std_logic_vector(7 downto 0);   -- Dado recebido do FIFO
    axis_tvalid  : out std_logic;                      -- Indica que há dado válido no FIFO
    axis_tready  : out std_logic;                      -- DÚVIDA

    -- Sinais de diagnóstico do UART
    frame_error  : out std_logic;                      -- Erro de stop bit
    parity_error : out std_logic;                      -- Erro de paridade
    busy         : out std_logic                       -- UART RX ocupado
  );
end top_module;

architecture rtl of top_module is

  ---------------------------------------------------------------------------
  -- Sinais internos
  ---------------------------------------------------------------------------
  signal baud_tick     : std_logic;

  -- Interface AXIS entre UART RX e FIFO TX
  signal s_axis_tdata  : std_logic_vector(7 downto 0);
  signal s_axis_tvalid : std_logic;
  signal s_axis_tready : std_logic;

  -- Saída do FIFO (para debug)
  signal fifo_tdata    : std_logic_vector(7 downto 0);
  signal fifo_tvalid   : std_logic;
  signal fifo_tready   : std_logic;

begin

  ---------------------------------------------------------------------------
  -- Gerador de Baud Rate (baud_gen)
  ---------------------------------------------------------------------------
  baud_gen_inst : entity work.baud_gen
    generic map (
      CLK_FREQ  => 50_000_000,  -- Clock principal em Hz
      BAUD_RATE => 115200       -- Taxa de baud desejada
    )
    port map (
      clk       => clk,
      reset_n   => reset_n,
      baud_tick => baud_tick
    );

  ---------------------------------------------------------------------------
  -- Receptor UART (uart_rx)
  -- Converte sinal serial em fluxo AXI-Stream
  ---------------------------------------------------------------------------
  uart_rx_inst : entity work.uart_rx
    generic map (
      DATA_BITS => 8,
      STOP_BITS => 1,
      PARITY    => "EVEN"
    )
    port map (
      clk          => clk,
      reset_n      => reset_n,
      rx           => rx,
      baud_tick    => baud_tick,

      -- Interface AXIS de saída (para FIFO)
      axis_tdata   => s_axis_tdata,
      axis_tvalid  => s_axis_tvalid,
      axis_tready  => s_axis_tready,

      -- Diagnósticos
      frame_error  => frame_error,
      parity_error => parity_error,
      busy         => busy
    );

  ---------------------------------------------------------------------------
  -- FIFO TX
  -- Recebe bytes via AXI-Stream e armazena para posterior leitura
  ---------------------------------------------------------------------------
  fifo_tx_inst : entity work.fifo_tx
    generic map (
      DATA_WIDTH => 8,
      DEPTH      => 16  -- FIFO de 16 bytes
    )
    port map (
      clk          => clk,
      reset_n      => reset_n,

      -- AXIS de entrada (vindo do UART RX)
      axis_tdata   => s_axis_tdata,
      axis_tvalid  => s_axis_tvalid,
      axis_tready  => s_axis_tready,

      -- Saída do FIFO (para debug)
      fifo_tdata   => fifo_tdata,
      fifo_tvalid  => fifo_tvalid,
      fifo_tready  => fifo_tready
    );

  ---------------------------------------------------------------------------
  -- Saídas externas (para observação e debug)
  ---------------------------------------------------------------------------
  axis_tdata  <= fifo_tdata;
  axis_tvalid <= fifo_tvalid;
  axis_tready <= fifo_tready;

end rtl;
