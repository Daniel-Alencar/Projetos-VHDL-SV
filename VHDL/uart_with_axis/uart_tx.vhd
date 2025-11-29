library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
  generic (
    DATA_BITS : integer := 8;
    STOP_BITS : integer := 1;
    PARITY    : string  := "NONE" -- "NONE", "EVEN" ou "ODD"
  );
  port (
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    baud_tick : in  std_logic;
    
    -- Interface de Controle
    tx_start  : in  std_logic; -- Pulso para iniciar transmissão
    tx_data   : in  std_logic_vector(DATA_BITS-1 downto 0);
    
    -- Saída Serial
    tx        : out std_logic;
    
    -- Status
    busy      : out std_logic
  );
end uart_tx;

architecture rtl of uart_tx is

  type state_type is (IDLE, START, DATA, PARITY_BIT, STOP);
  signal state : state_type := IDLE;

  signal bit_index   : integer range 0 to DATA_BITS-1 := 0;
  signal data_reg    : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');
  signal stop_count  : integer range 0 to STOP_BITS + 1 := 0;
  signal parity_calc : std_logic := '0';
  signal tx_reg      : std_logic := '1';

begin
  
  tx <= tx_reg;

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      state       <= IDLE;
      tx_reg      <= '1'; -- Linha idle em nível alto
      busy        <= '0';
      bit_index   <= 0;
      parity_calc <= '0';
      
    elsif rising_edge(clk) then
      
      case state is
        ------------------------------------------------------------------
        when IDLE =>
          tx_reg <= '1';
          if tx_start = '1' then
            state       <= START;
            data_reg    <= tx_data; -- Latcheia o dado
            busy        <= '1';
            parity_calc <= '0';     -- Reseta cálculo de paridade
          else
            busy <= '0';
          end if;

        ------------------------------------------------------------------
        when START =>
          if baud_tick = '1' then
            tx_reg <= '0'; -- Start bit é 0
            state  <= DATA;
            bit_index <= 0;
          end if;

        ------------------------------------------------------------------
        when DATA =>
          if baud_tick = '1' then
            tx_reg <= data_reg(bit_index);
            -- Calcula paridade (XOR acumulativo)
            parity_calc <= parity_calc xor data_reg(bit_index);
            
            if bit_index = DATA_BITS-1 then
              if PARITY = "NONE" then
                state <= STOP;
              else
                state <= PARITY_BIT;
              end if;
            else
              bit_index <= bit_index + 1;
            end if;
          end if;

        ------------------------------------------------------------------
        when PARITY_BIT =>
          if baud_tick = '1' then
            if PARITY = "EVEN" then
              tx_reg <= parity_calc;
            elsif PARITY = "ODD" then
              tx_reg <= not parity_calc;
            end if;
            state <= STOP;
          end if;

        ------------------------------------------------------------------
        when STOP =>
          if baud_tick = '1' then
            tx_reg <= '1'; -- Stop bit é 1
            
            if stop_count = STOP_BITS-1 then
              state      <= IDLE;
              busy       <= '0';
              stop_count <= 0;
            else
              stop_count <= stop_count + 1;
            end if;
          end if;
          
      end case;
    end if;
  end process;
end rtl;