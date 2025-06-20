library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--===========================--
-- Entidade do Flip-Flop    --
--===========================--
entity dff_8bit is
    Port (
        clk : in std_logic;
        ce  : in std_logic;
        rst : in std_logic;
        d   : in std_logic_vector(7 downto 0);
        q   : out std_logic_vector(7 downto 0)
    );
end dff_8bit;

architecture rtl of dff_8bit is
    signal reg : std_logic_vector(7 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= (others => '0');
            elsif ce = '1' then
                reg <= d;
            end if;
        end if;
    end process;

    q <= reg;
end rtl;
