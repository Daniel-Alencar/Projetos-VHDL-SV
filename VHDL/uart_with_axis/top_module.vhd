library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    rx           : in  std_logic;
    tx           : out std_logic
    -- REMOVIDAS todas as portas de debug (axis_*, erros, busy)
    -- pois elas não têm pinos na placa.
  );
end top_module;

architecture rtl of top_module is

  -- Sinais internos
  signal baud_tick     : std_logic;

  -- Interface UART RX -> FIFO TX
  signal s_axis_tdata  : std_logic_vector(7 downto 0);
  signal s_axis_tvalid : std_logic;
  signal s_axis_tready : std_logic;

  -- FIFO TX -> FIFO RX
  signal fifo_tdata0    : std_logic_vector(7 downto 0);
  signal fifo_tvalid0   : std_logic;
  signal fifo_tready0   : std_logic;

  -- FIFO RX -> UART TX
  signal fifo_tdata1    : std_logic_vector(7 downto 0);
  signal fifo_tvalid1   : std_logic;
  signal fifo_tready1   : std_logic;

  -- Controle do UART TX
  signal tx_busy        : std_logic;
  signal tx_start       : std_logic;

  -- Sinais "Dummy" (para conectar as saídas de debug que não usaremos externamente)
  signal ignore_data    : std_logic_vector(7 downto 0);
  signal ignore_valid   : std_logic;
  signal ignore_ready   : std_logic;
  signal ignore_error1  : std_logic;
  signal ignore_error2  : std_logic;
  signal ignore_busy    : std_logic;

begin

  -- 1. Gerador de Baud Rate (Lembre-se: 25MHz para Colorlight i9+)
  baud_gen_inst : entity work.baud_gen
    generic map (
      CLK_FREQ  => 25_000_000, 
      BAUD_RATE => 115200      
    )
    port map (
      clk       => clk,
      reset_n   => reset_n,
      baud_tick => baud_tick
    );

  -- 2. Receptor UART
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
      axis_tdata   => s_axis_tdata,
      axis_tvalid  => s_axis_tvalid,
      axis_tready  => s_axis_tready,
      -- Conectamos em sinais internos que não vão a lugar nenhum
      frame_error  => ignore_error1,
      parity_error => ignore_error2,
      busy         => ignore_busy
    );

  -- 3. FIFO Intermediária 1 (TX)
  fifo_tx_inst : entity work.fifo_tx
    generic map ( DATA_WIDTH => 8, DEPTH => 16 )
    port map (
      clk          => clk,
      reset_n      => reset_n,
      axis_tdata   => s_axis_tdata,
      axis_tvalid  => s_axis_tvalid,
      axis_tready  => s_axis_tready,
      fifo_tdata   => fifo_tdata0,
      fifo_tvalid  => fifo_tvalid0,
      fifo_tready  => fifo_tready0
    );

  -- 4. FIFO Intermediária 2 (RX)
  fifo_rx_inst : entity work.fifo_tx
    generic map ( DATA_WIDTH => 8, DEPTH => 16 )
    port map (
      clk          => clk,
      reset_n      => reset_n,
      axis_tdata   => fifo_tdata0,
      axis_tvalid  => fifo_tvalid0,
      axis_tready  => fifo_tready0,
      fifo_tdata   => fifo_tdata1,
      fifo_tvalid  => fifo_tvalid1,
      fifo_tready  => fifo_tready1
    );

  -- 5. Lógica de Controle
  process(fifo_tvalid1, tx_busy)
  begin
    if (fifo_tvalid1 = '1' and tx_busy = '0') then
      tx_start     <= '1';
      fifo_tready1 <= '1';
    else
      tx_start     <= '0';
      fifo_tready1 <= '0';
    end if;
  end process;

  -- 6. Transmissor UART
  uart_tx_inst : entity work.uart_tx
    generic map (
      DATA_BITS => 8,
      STOP_BITS => 1,
      PARITY    => "EVEN"
    )
    port map (
      clk       => clk,
      reset_n   => reset_n,
      baud_tick => baud_tick,
      tx_start  => tx_start,
      tx_data   => fifo_tdata1,
      tx        => tx,
      busy      => tx_busy
    );

end rtl;