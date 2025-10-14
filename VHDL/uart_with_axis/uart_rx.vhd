library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ==========================================================================
-- uart_rx.vhd
-- Receptor UART simples baseado em um pulso de "baud_tick".
-- - Gera data_ready (1 ciclo) quando um byte válido é recebido.
-- - Sinaliza frame_error se o stop bit for inválido.
-- - Usa sincronização de 2 flip-flops para o sinal 'rx'.
-- - Não implementa paridade nem oversampling (versão simplificada).
-- ==========================================================================
entity uart_rx is
  generic (
    DATA_BITS : integer := 8;  -- número de bits de dados a receber (ex.: 8)
    STOP_BITS : integer := 1   -- não utilizado internamente na versão atual
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
  -- Sincronizador do sinal RX
  -- Observação: escrever apenas rx_sync(1) em todo o código para usar versão segura.
  ----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      rx_sync(0) <= rx;         -- primeira amostra (assíncrona -> síncrona)
      rx_sync(1) <= rx_sync(0); -- segunda amostra (estabilizada)
    end if;
  end process;


  ----------------------------------------------------------------------------
  -- Máquina de estados principal do receptor UART
  --
  -- Observação sobre amostragem:
  -- - Este código assume que 'baud_tick' já está alinhado de forma que cada
  --   pulso corresponde ao momento em que desejamos amostrar o próximo bit.
  -- - Para maior robustez use oversampling (ex.: 16x) para detectar bordas de
  --   start e amostrar no centro do bit. Aqui usamos confirmação simples do
  --   start (estado START) para reduzir falsos disparos por ruído.
  ----------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    -- Reset assíncrono síncrono (ativa em nível baixo)
    if reset_n = '0' then
      state        <= IDLE;
      bit_counter  <= 0;
      shift_reg    <= (others => '0');
      data_ready_i <= '0';
      frame_err_i  <= '0';
      busy_i       <= '0';
    elsif rising_edge(clk) then

      -- Garantimos que data_ready é apenas um pulso: limpamos a cada ciclo
      data_ready_i <= '0';

      -- Só reagimos quando houver um pulso de baud (amostragem por bit)
      if baud_tick = '1' then
        case state is

          -- =================================================================
          when IDLE =>
            -- Receptor está inativo. Aguarda borda de start (linha RX caiu para '0').
            busy_i <= '0';            -- não ocupado
            frame_err_i <= '0';       -- limpa erro anterior
            if rx_sync(1) = '0' then  -- possível start bit detectado

              -- Passa para estado de confirmação do start
              state <= START;
              busy_i <= '1';  -- marca ocupado imediatamente
            end if;

          -- =================================================================
          when START =>
            -- Confirmação simples do start: verifica se o bit ainda é '0'.
            -- Se confirmado, inicia leitura dos bits de dados.
            -- Caso contrário, era ruído; volta ao IDLE.
            if rx_sync(1) = '0' then
              bit_counter <= 0;   -- prepara contador para o primeiro data bit
              state <= DATA;
            else
              -- falso alarme, retorna a IDLE
              state <= IDLE;
            end if;

          -- =================================================================
          when DATA =>
            -- Aqui lemos um bit de dados por vez (LSB primeiro).
            -- Armazenamos na posição bit_counter do shift_reg.
            shift_reg(bit_counter) <= rx_sync(1);

            -- Se já lemos o último bit, passamos para STOP na próxima amostragem
            if bit_counter = DATA_BITS - 1 then
              state <= STOP;
            else
              -- caso contrário incrementa contador para o próximo bit
              bit_counter <= bit_counter + 1;
            end if;

          -- =================================================================
          when STOP =>
            -- Verifica o bit de parada (deve ser '1' em UART padrão).
            if rx_sync(1) = '1' then
              -- Frame válido: emite pulso data_ready por 1 ciclo
              data_ready_i <= '1';
              frame_err_i <= '0';
            else
              -- Stop inválido -> frame error
              frame_err_i <= '1';
            end if;
            -- Em qualquer caso voltamos para IDLE para aguardar novo frame
            state <= IDLE;

          -- =================================================================
          when others =>
            -- segurança contra estados inválidos
            state <= IDLE;

        end case;
      end if; -- fim if baud_tick
    end if; -- fim rising_edge
  end process;


  ----------------------------------------------------------------------------
  -- Ligação das saídas (sinais internos -> portas)
  ----------------------------------------------------------------------------
  data_out    <= shift_reg;     -- dado paralelo recebido
  data_ready  <= data_ready_i;  -- pulso 1 ciclo quando byte pronto
  frame_error <= frame_err_i;   -- erro de frame (stop inválido)
  busy        <= busy_i;        -- receptor ocupado

end rtl;
