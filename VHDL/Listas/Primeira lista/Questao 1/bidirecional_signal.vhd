library ieee;
use ieee.std_logic_1164.all;

entity bidirectional_signal is
    port (
        a : in std_logic;
        b : inout std_logic;
        c : inout std_logic;
        d : out std_logic
    );
end entity;

architecture rtl of bidirectional_signal is
    signal b_reg : std_logic;
    signal c_reg : std_logic;
    signal d_i   : std_logic;
begin
    -- Buffer 3-state para c: habilitado quando a = '1' (b -> c)
    c <= b when a = '1' else 'Z';

    -- Buffer 3-state para b: habilitado quando a = '0' (c -> b)
    b <= c when a = '0' else 'Z';

    -- Lógica da saída d: inverso do valor atual de c (quando lido)
    d <= not c;

end architecture;
