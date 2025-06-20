library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signed_counter is
    port(
        clk : in std_logic;
        reset : in std_logic;
        -- Utiliza aritmética em complemento de 2
        output : out signed(7 downto 0)
    );
end entity;

architecture rtl of signed_counter is
    signal count : signed(7 downto 0) := (others => '0');
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- Atribui 0 para cada bit
            count <= (others => '0');
        elsif rising_edge(clk) then
            -- Não é preciso verificar se chegou no limite porque o tipo "signed" já faz o ciclo automaticamente. Ele implementa o que se chama "wrap-around"
            count <= count + 1;
        end if;
    end process;

    -- | Binário           | Decimal |
    -- | ----------------- | ------- |
    -- | `01111111` (127)  | 127     |
    -- | `10000000` (-128) | -128    |
    -- | `10000001` (-127) | -127    |
    -- | `...`             | ...     |
    -- | `11111111` (-1)   | -1      |
    -- | `00000000` (0)    | 0       |
    -- | `00000001` (1)    | 1       |
    -- | `...`             | ...     |

    output <= count;
end architecture;
