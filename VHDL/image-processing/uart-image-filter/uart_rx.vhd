library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
  generic (
    DATA_BITS : integer := 8;
    STOP_BITS : integer := 1;
    PARITY    : string  := "NONE";
    CLK_FREQ  : integer := 25_000_000; -- Frequência do seu Clock
    BAUD_RATE : integer := 115_200     -- Baud Rate desejado
  );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    rx           : in  std_logic;
    -- baud_tick removido: o RX gerencia seu próprio tempo para sincronizar

    -- Interface AXI-Stream de saída
    axis_tdata   : out std_logic_vector(DATA_BITS-1 downto 0);
    axis_tvalid  : out std_logic;
    axis_tready  : in  std_logic;

    -- Sinais de status e erro
    frame_error  : out std_logic;
    parity_error : out std_logic;
    busy         : out std_logic
  );
end uart_rx;

architecture rtl of uart_rx is

  -- Constantes de temporização
  constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;
  constant HALF_BIT   : integer := BIT_PERIOD / 2;

  type state_type is (IDLE, START, DATA, PARITY_BIT, STOP, WAIT_READY);
  signal state       : state_type := IDLE;

  signal bit_index   : integer range 0 to DATA_BITS-1 := 0;
  signal rx_shift    : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');
  signal stop_count  : integer range 0 to STOP_BITS + 1 := 0;

  -- Contador para amostragem
  signal sample_cnt  : integer range 0 to BIT_PERIOD + 1 := 0;

  signal rx_reg, rx_sync : std_logic := '1';
  signal parity_calc     : std_logic := '0';
  signal parity_recv     : std_logic := '0';

  signal tvalid_int : std_logic := '0';
  signal tdata_int  : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');

begin
  -- Saídas
  axis_tdata  <= tdata_int;
  axis_tvalid <= tvalid_int;

  -- Sincronização do sinal RX (Double Flop para evitar metaestabilidade)
  process(clk)
  begin
    if rising_edge(clk) then
      rx_sync <= rx;
      rx_reg  <= rx_sync;
    end if;
  end process;

  -- Máquina de estados UART RX
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      state        <= IDLE;
      bit_index    <= 0;
      sample_cnt   <= 0;
      rx_shift     <= (others => '0');
      parity_calc  <= '0';
      frame_error  <= '0';
      parity_error <= '0';
      busy         <= '0';
      tvalid_int   <= '0';
    elsif rising_edge(clk) then
      case state is

        ------------------------------------------------------------------
        when IDLE =>
          busy <= '0';
          frame_error  <= '0';
          parity_error <= '0';
          sample_cnt   <= 0;
          bit_index    <= 0;

          if rx_reg = '0' and tvalid_int = '0' then 
            state <= START;
            busy  <= '1';
          end if;

        ------------------------------------------------------------------
        when START =>
          -- Espera MEIO bit para verificar se ainda é 0 (filtro de ruído e centralização)
          if sample_cnt = HALF_BIT then
            if rx_reg = '0' then
              sample_cnt <= 0; -- Reseta contador para contar 1 bit inteiro agora
              parity_calc <= '0';
              state <= DATA;
            else
              state <= IDLE; -- Era ruído
              busy  <= '0';
            end if;
          else
            sample_cnt <= sample_cnt + 1;
          end if;

        ------------------------------------------------------------------
        when DATA =>
          -- Agora esperamos um periodo INTEIRO para cair no meio do próximo bit
          if sample_cnt = BIT_PERIOD - 1 then
            sample_cnt <= 0;
            rx_shift(bit_index) <= rx_reg; -- Amostra o dado
            parity_calc <= parity_calc xor rx_reg;

            if bit_index = DATA_BITS-1 then
              if PARITY = "NONE" then
                state <= STOP;
              else
                state <= PARITY_BIT;
              end if;
            else
              bit_index <= bit_index + 1;
            end if;
          else
            sample_cnt <= sample_cnt + 1;
          end if;

        ------------------------------------------------------------------
        when PARITY_BIT =>
          if sample_cnt = BIT_PERIOD - 1 then
            sample_cnt <= 0;
            parity_recv <= rx_reg;

            if PARITY = "EVEN" then
              if parity_calc /= rx_reg then parity_error <= '1'; end if;
            elsif PARITY = "ODD" then
              if parity_calc = rx_reg then parity_error <= '1'; end if;
            end if;
            state <= STOP;
          else
            sample_cnt <= sample_cnt + 1;
          end if;

        ------------------------------------------------------------------
        when STOP =>
          if sample_cnt = BIT_PERIOD - 1 then
            sample_cnt <= 0;
            if rx_reg = '1' then
              if stop_count = STOP_BITS-1 then
                tdata_int  <= rx_shift;
                tvalid_int <= '1';
                busy       <= '0';
                stop_count <= 0;
                state      <= WAIT_READY;
              else
                stop_count <= stop_count + 1;
              end if;
            else
              frame_error <= '1';
              busy  <= '0';
              state <= IDLE;
            end if;
          else
            sample_cnt <= sample_cnt + 1;
          end if;

        ------------------------------------------------------------------
        when WAIT_READY =>
          if axis_tready = '1' then
            tvalid_int <= '0';
            state <= IDLE;
          end if;

      end case;
    end if;
  end process;
end rtl;