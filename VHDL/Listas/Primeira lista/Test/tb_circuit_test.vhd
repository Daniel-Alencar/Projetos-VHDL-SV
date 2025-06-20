library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_circuito_test is
end tb_circuito_test;

architecture test of tb_circuito_test is
    signal a, b, y : STD_LOGIC;
begin
    uut: entity work.circuito_test
        port map (
            a => a,
            b => b,
            y => y
        );

    stim_proc: process
    begin
        a <= '0'; b <= '0'; wait for 10 ns;
        a <= '0'; b <= '1'; wait for 10 ns;
        a <= '1'; b <= '0'; wait for 10 ns;
        a <= '1'; b <= '1'; wait for 10 ns;
        wait;
    end process;
end test;
