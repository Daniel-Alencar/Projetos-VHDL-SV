library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mux_pkg.all;

entity tb_mux_ff_quad_top is
end entity;

architecture sim of tb_mux_ff_quad_top is
    -- Sinais
    signal clk        : std_logic := '0';
    signal ce         : std_logic := '0';
    signal rst        : std_logic := '0';
    signal sel        : std_logic_vector(1 downto 0) := (others => '0');
    signal bus_array  : slv8_array16 := (others => (others => '0'));

    signal q_case     : std_logic_vector(7 downto 0);
    signal q_if       : std_logic_vector(7 downto 0);
    signal q_when     : std_logic_vector(7 downto 0);
    signal q_with     : std_logic_vector(7 downto 0);

    constant clk_period : time := 10 ns;
begin

    -- Geração do clock
    clk_process: process
    begin
        while now < 500 ns loop
            clk <= '0'; wait for clk_period / 2;
            clk <= '1'; wait for clk_period / 2;
        end loop;
        wait;
    end process;

    dut: entity work.mux_ff_quad_top(rtl)
        port map (
            clk => clk,
            ce => ce,
            rst => rst,
            sel => sel,
            bus_array => bus_array,
            q_case => q_case,
            q_if => q_if,
            q_when => q_when,
            q_with => q_with
        );

    stimulus_proc: process
    begin
        -- Reset inicial
        ce <= '0';
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        ce <= '1';

        -- Altera entradas
        for i in 0 to 15 loop
            bus_array(i) <= std_logic_vector(to_unsigned(16#A0# + i, 8));
        end loop;

        -- Testa seletores 00 a 11
        for i in 0 to 3 loop
            sel <= std_logic_vector(to_unsigned(i, 2));
            wait for clk_period;
        end loop;

        -- Altera entradas
        for i in 0 to 15 loop
            bus_array(i) <= std_logic_vector(to_unsigned(16#10# * i, 8));
        end loop;

        -- Testa seletores 00 a 11
        for i in 0 to 3 loop
            sel <= std_logic_vector(to_unsigned(i, 2));
            wait for clk_period;
        end loop;

        -- Aplica reset durante operação
        rst <= '1';
        wait for clk_period;
        rst <= '0';

        -- Clock enable desativado (saídas não devem mudar)
        ce <= '0';
        sel <= "10";
        wait for clk_period;

        -- Clock enable ativado novamente
        ce <= '1';
        sel <= "01";
        wait for clk_period;

        wait;
    end process;

end architecture;
