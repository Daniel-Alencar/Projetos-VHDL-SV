library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity baud_gen is
  generic (
    CLK_FREQ  : natural := 50_000_000;  -- frequência do clock em Hz
    BAUD_RATE : natural := 115_200      -- taxa de baud
  );
  port (
    clk       : in  std_logic;
    reset_n   : in  std_logic;           -- reset ativo em nível baixo
    baud_tick : out std_logic            -- pulso de 1 ciclo por baud
  );
end baud_gen;

architecture rtl of baud_gen is

  -- Calcula o número de ciclos por bit com arredondamento
  constant BAUD_TICK_COUNT : 
    integer := integer(real(CLK_FREQ) / real(BAUD_RATE) + 0.5);

  signal counter : integer range 0 to BAUD_TICK_COUNT - 1 := 0;
  signal tick    : std_logic := '0';

begin

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      counter <= 0;
      tick <= '0';
    elsif rising_edge(clk) then
      if counter = BAUD_TICK_COUNT - 1 then
        counter <= 0;
        tick <= '1';  -- gera pulso
      else
        counter <= counter + 1;
        tick <= '0';
      end if;
    end if;
  end process;

  baud_tick <= tick;

end rtl;
