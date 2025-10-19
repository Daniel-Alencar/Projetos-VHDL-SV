library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ==========================================================================
-- uart_rx.vhd (corrigido)
-- - Detecta start imediatamente (IDLE reage em 1 ciclo de clock).
-- - START/DATA/STOP avançam somente em pulsos `baud_tick`.
-- - Usa dupla sincronização do sinal RX (evita metastabilidade).
-- - Não implementa oversampling nem paridade (simplicidade).
-- ==========================================================================
entity uart_rx is
  generic (
    DATA_BITS : integer := 8;  -- número de bits de dados
    STOP_BITS : integer := 1   -- não usado para múltiplos stop bits aqui
  );
  port (
    clk         : in  std_logic;                                   -- clock da FPGA
    reset_n     : in  std_logic;                                   -- reset ativo baixo
    rx          : in  std_logic;                                   -- linha serial input (idle = '1')
    baud_tick   : in  std_logic;                                   -- pulso de 1 ciclo por bit (de baud_gen)
    data_out    : out std_logic_vector(DATA_BITS-1 downto 0);      -- byte recebido
    data_ready  : out std_logic;                                   -- pulso 1 ciclo: dado pronto
    frame_error : out std_logic;                                   -- erro de frame (stop inválido)
    busy        : out std_logic                                    -- receptor ocupado
  );
end uart_rx;

architecture rtl of uart_rx is

  -- FSM states para o receptor
  type state_type is (IDLE, START, DATA, STOP);
  signal state : state_type := IDLE;

  -- Contador de bits (0 .. DATA_BITS-1)
  signal bit_counter : integer range 0 to DATA_BITS-1 := 0;

  -- Registrador de deslocamento onde montamos o byte recebido
  signal shift_reg : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');

  -- Dupla sincronização do sinal rx para evitar metastabilidade
  -- rx_sync(0) é a primeira amostra, rx_sync(1) é a amostra estabilizada usada pelo FSM
  signal rx_sync : std_logic_vector(1 downto 0) := (others => '1');

  -- Sinais internos para saída (permitimos controlar pulso de 1 ciclo)
  signal data_ready_i : std_logic := '0';
  signal frame_err_i  : std_logic := '0';
  signal busy_i       : std_logic := '0';

begin

  ----------------------------------------------------------------------------
  -- Sincronizador do sinal RX (dupla-flop). Executa todo ciclo de clock.
  ----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      rx_sync(0) <= rx;         -- primeira amostra (assíncrona -> síncrona)
      rx_sync(1) <= rx_sync(0); -- segunda amostra (estabilizada)
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- Máquina de estados principal do receptor UART (com correção)
  -- - O IDLE verifica rx_sync(1) em todo ciclo de clock e sai imediatamente
  --   para START assim que detecta a linha em '0'.
  -- - START / DATA / STOP avançam apenas no pulso baud_tick = '1'.
  ----------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    -- Reset ativo em nível baixo
    if reset_n = '0' then
      state        <= IDLE;
      bit_counter  <= 0;
      shift_reg    <= (others => '0');
      data_ready_i <= '0';
      frame_err_i  <= '0';
      busy_i       <= '0';
    elsif rising_edge(clk) then

      -- Garante que data_ready é apenas um pulso (limpa sempre por padrão)
      data_ready_i <= '0';

      -- -------------- DETECÇÃO IMEDIATA DO START (fora do baud_tick) --------------
      if state = IDLE then
        busy_i <= '0';
        frame_err_i <= '0';
        -- Se a linha caiu para '0', é um start bit — reagimos imediatamente
        if rx_sync(1) = '0' then
          state <= START;
          busy_i <= '1';
        end if;

      -- -------------- PARA OS DEMAIS ESTADOS, AVANÇAMOS SÓ EM baud_tick --------------
      else
        if baud_tick = '1' then
          case state is

            when START =>
              -- Confirmação do start: se ainda é '0' seguimos, caso contrário
              -- trata-se de ruído e voltamos para IDLE.
              if rx_sync(1) = '0' then
                bit_counter <= 0;
                state <= DATA;
              else
                state <= IDLE;
                busy_i <= '0';
              end if;

            when DATA =>
              -- Amostra um bit de dados por vez (LSB first)
              shift_reg(bit_counter) <= rx_sync(1);

              if bit_counter = DATA_BITS - 1 then
                state <= STOP;
              else
                bit_counter <= bit_counter + 1;
              end if;

            when STOP =>
              -- Verifica o bit de parada (deve ser '1')
              if rx_sync(1) = '1' then
                data_ready_i <= '1';  -- byte válido pronto (pulso)
                frame_err_i <= '0';
              else
                frame_err_i <= '1';
              end if;
              state <= IDLE;
              busy_i <= '0';

            when others =>
              state <= IDLE;
              busy_i <= '0';

          end case;
        end if; -- fim if baud_tick
      end if; -- fim if state = IDLE

    end if; -- fim rising_edge
  end process;

  ----------------------------------------------------------------------------
  -- Saídas
  ----------------------------------------------------------------------------
  data_out    <= shift_reg;
  data_ready  <= data_ready_i;
  frame_error <= frame_err_i;
  busy        <= busy_i;

end rtl;
