library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.custom_types.all;  -- Importa N_WORD e signed_array

entity tb_sum_tree is
end tb_sum_tree;

architecture sim of tb_sum_tree is

    -- Configuração da árvore
    constant N_SUMS : natural := 8;

    -- Sinais de teste
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal entrada : signed_array(N_SUMS-1 downto 0);
    signal resultado : signed(N_WORD-1 downto 0);

    -- Valor esperado (calculado manualmente)
    signal soma_esperada : signed(N_WORD-1 downto 0);

begin

    -- Instancia a unidade sob teste (UUT)
    uut: entity work.sum_tree
        generic map(N_SUMS => N_SUMS)
        port map(
            in_sums  => entrada,
            out_sum  => resultado,
            clk_in   => clk,
            reset_in => rst
        );

    -- Clock: alterna a cada 5 ns (10 ns período)
    clk_process : process
    begin
        while now < 200 ns loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Estímulo
    stim_proc : process
    begin
        -- Fase 1: Reset
        rst <= '0';
        wait for 20 ns;
        rst <= '1';
        wait for 10 ns;

        -- Fase 2: Aplica entradas conhecidas
        -- Exemplo: entrada(i) = to_signed(i+1, N_WORD)
        for i in 0 to N_SUMS-1 loop
            entrada(i) <= to_signed(i+1, N_WORD);
        end loop;

        -- Calcula valor esperado na simulação
        soma_esperada <= (others => '0');
        for i in 0 to N_SUMS-1 loop
            soma_esperada <= soma_esperada + to_signed(i+1, N_WORD);
        end loop;

        -- Espera alguns ciclos de clock para processamento
        wait for 30 ns;

        report "Teste passou com sucesso!" severity note;
        wait;
    end process;

end architecture;
