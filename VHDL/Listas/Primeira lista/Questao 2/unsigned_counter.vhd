library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unsigned_counter is
    port(
        clk : in std_logic;
        reset : in std_logic;
        output : out unsigned(7 downto 0)
    );
end entity;

architecture rtl of unsigned_counter is
    signal count : unsigned(7 downto 0) := (others => '0');
begin
    process(clk, reset)
    begin
        if reset = '1' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            count <= count + 1;
        end if;
    end process;

    output <= count;
end architecture;
