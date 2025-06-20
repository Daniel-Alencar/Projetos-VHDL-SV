library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mux_ff_top is
end entity;

architecture sim of tb_mux_ff_top is
    -- Sinais de entrada
    signal clk     : std_logic := '0';
    signal ce      : std_logic := '0';
    signal rst     : std_logic := '0';
    signal sel     : std_logic_vector(1 downto 0) := (others => '0');
    signal a, b, c, d : std_logic_vector(7 downto 0);

    -- Saída
    signal q_out   : std_logic_vector(7 downto 0);

    -- Clock período
    constant clk_period : time := 10 ns;
begin

    -- Geração do clock
    clk_process : process
    begin
        while now < 500 ns loop
            clk <= '0'; wait for clk_period / 2;
            clk <= '1'; wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- Instância do DUT (use_with, pode mudar)
    dut: entity work.mux_ff_top
        port map (
            clk  => clk,
            ce   => ce,
            rst  => rst,
            sel  => sel,
            a    => a,
            b    => b,
            c    => c,
            d    => d,
            q_out => q_out
        );

    -- Processo de estímulo
    stimulus_proc: process
    begin
        -- Inicialização
        ce <= '0';
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        ce <= '1';

        -- Valores fixos para testar o mux
        a <= x"A1";
        b <= x"B2";
        c <= x"C3";
        d <= x"D4";

        -- Testa todas as seleções do mux
        for i in 0 to 3 loop
            sel <= std_logic_vector(to_unsigned(i, 2));
            wait for clk_period;
        end loop;

        -- Testa mudança de entradas
        a <= x"11"; 
        b <= x"22"; 
        c <= x"33"; 
        d <= x"44";

        for i in 0 to 3 loop
            sel <= std_logic_vector(to_unsigned(i, 2));
            wait for clk_period;
        end loop;

        -- Testa reset durante operação
        rst <= '1';
        wait for clk_period;
        rst <= '0';

        -- Testa clock enable desativado
        ce <= '0';
        sel <= "01";  -- mudar seletor mas FF não deve armazenar
        wait for clk_period;

        -- Reativa clock enable
        ce <= '1';
        sel <= "10";
        wait for clk_period;

        -- Fim do teste
        wait;
    end process;

end architecture;
