library ieee;
use ieee.std_logic_1164.all;

entity integer_counter is
    port(
        clk : in std_logic;
        reset : in std_logic;
        -- Variável inteira que vai de -128 a 127
        output : out integer range -128 to 127
    );
end entity;

architecture rtl of integer_counter is
    -- o sinal interno count é inicializado com 0
    signal count : integer range -128 to 127 := 0;
begin

    -- O processo de contagem sempre acontece quando houver uma transição em clk ou reset
    process(clk, reset)
    begin
        if reset = '1' then
            count <= 0;
        elsif rising_edge(clk) then
            if count = 127 then
                -- Para reiniciar no limite inferior
                count <= -128; 
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    -- output sempre reflete o valor de count
    output <= count;
end architecture;
