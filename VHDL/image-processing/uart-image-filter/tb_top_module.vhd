library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_module is
end tb_top_module;

architecture tb of tb_top_module is

  ---------------------------------------------------------------------------
  -- CONFIGURAÇÕES (Ajuste conforme seu Top Module real)
  ---------------------------------------------------------------------------
  -- IMPORTANTE: Se o top_module está configurado para 25 MHz (Colorlight),
  -- mude aqui para 25_000_000. Se estiver usando 50 MHz, mantenha.
  constant CLK_FREQ   : integer := 25_000_000; 
  constant CLK_PERIOD : time := 1 sec / CLK_FREQ;
  
  constant BAUD_RATE  : integer := 115200;
  constant BIT_PERIOD : time := 1 sec / BAUD_RATE;

  constant PARITY_MODE : string := "NONE"; 
  constant STOP_BITS   : integer := 1;

  signal clk          : std_logic := '0';
  signal reset_n      : std_logic := '0';
  signal rx           : std_logic := '1';
  signal tx           : std_logic;

begin

  -- Geração de Clock
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  -- DUT (Device Under Test)
  uut : entity work.top_module
    port map (
      clk          => clk,
      reset_n      => reset_n,
      rx           => rx,
      tx           => tx
    );

  -- Processo de Estímulo
  stim_proc : process

    -- 1. Função de cálculo de paridade (MANTIDA IGUAL)
    function calc_parity(data : std_logic_vector; mode : string) return std_logic is
      variable ones : integer := 0;
    begin
      for i in data'range loop
        if data(i) = '1' then ones := ones + 1; end if;
      end loop;

      if mode = "EVEN" then
        if (ones mod 2) = 0 then return '0'; else return '1'; end if;
      elsif mode = "ODD" then
        if (ones mod 2) = 0 then return '1'; else return '0'; end if;
      else return '0'; end if;
    end function;

    -- 2. Procedure para enviar UM BYTE (MANTIDA IGUAL)
    procedure send_byte(
      signal rx_line : out std_logic;
      data           : std_logic_vector(7 downto 0);
      parity_mode    : string;
      stop_bits      : integer
    ) is
      variable parity_bit : std_logic;
    begin
      parity_bit := calc_parity(data, parity_mode);

      -- Start bit
      rx_line <= '0';
      wait for BIT_PERIOD;

      -- Dados (LSB primeiro)
      for i in 0 to 7 loop
        rx_line <= data(i);
        wait for BIT_PERIOD;
      end loop;

      -- Paridade
      if parity_mode /= "NONE" then
        rx_line <= parity_bit;
        wait for BIT_PERIOD;
      end if;

      -- Stop bits
      rx_line <= '1';
      for i in 1 to stop_bits loop
        wait for BIT_PERIOD;
      end loop;
    end procedure;

    -- 3. NOVA PROCEDURE: Enviar STRING completa
    procedure send_string(
      signal rx_line : out std_logic;
      msg            : string;
      parity_mode    : string;
      stop_bits      : integer
    ) is
      variable char_byte : std_logic_vector(7 downto 0);
    begin
      -- Itera sobre cada caractere da string
      for i in msg'range loop
        -- Converte Character -> Integer -> Unsigned -> Std_Logic_Vector
        char_byte := std_logic_vector(to_unsigned(character'pos(msg(i)), 8));
        
        -- Chama a função de envio de byte
        send_byte(rx_line, char_byte, parity_mode, stop_bits);
        
        -- Nota: Não colocamos 'wait' aqui para simular o envio "Back-to-Back"
        -- que é o cenário mais estressante para o UART (onde ocorrem os erros de frame).
      end loop;
    end procedure;

  begin
    -- Inicialização
    reset_n <= '0';
    wait for 100 ns;
    reset_n <= '1';
    wait for 100 us; -- Tempo para o sistema estabilizar

    report "=== Teste 1: Envio de Byte isolado (Caractere 'a') ===";
    -- 'a' em ASCII é 0x61
    send_string(rx, "a", PARITY_MODE, STOP_BITS);
    wait for 20 * BIT_PERIOD; -- Pausa longa

    report "=== Teste 2: Envio de String Continua ('daniel') ===";
    -- Isso vai testar o comportamento de Start bit colado no Stop bit anterior
    send_string(rx, "daniel", PARITY_MODE, STOP_BITS);
    wait for 20 * BIT_PERIOD; -- Pausa longa

    report "=== Teste 3: Envio de String Continua ('danielalencarpenhacarvalho') ===";
    -- Isso vai testar o comportamento de Start bit colado no Stop bit anterior
    send_string(rx, "danielalencarpenhacarvalho", PARITY_MODE, STOP_BITS);
    wait for 20 * BIT_PERIOD; -- Pausa longa

    report "=== Teste 4: Envio de String Continua ('danielalencarpenhacarvalho') ===";
    -- Isso vai testar o comportamento de Start bit colado no Stop bit anterior
    send_string(rx, "danielalencarpenhacarvalho", PARITY_MODE, STOP_BITS);
    wait for 20 * BIT_PERIOD; -- Pausa longa

    report "=== Teste 5: Envio de String Continua ('danielalencarpenhacarvalho') ===";
    -- Isso vai testar o comportamento de Start bit colado no Stop bit anterior
    send_string(rx, "danielalencarpenhacarvalho", PARITY_MODE, STOP_BITS);
    wait for 20 * BIT_PERIOD; -- Pausa longa

    report "=== Teste 6: Envio de String Continua ('danielalencarpenhacarvalho') ===";
    -- Isso vai testar o comportamento de Start bit colado no Stop bit anterior
    send_string(rx, "danielalencarpenhacarvalho", PARITY_MODE, STOP_BITS);
    wait for 20 * BIT_PERIOD; -- Pausa longa

    wait for 500 us;
    report "=== Fim da Simulação ===";
    wait;
  end process;

end tb;