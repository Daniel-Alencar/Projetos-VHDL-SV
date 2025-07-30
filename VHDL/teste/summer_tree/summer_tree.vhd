-- Implementação recursiva
-- Árvore de soma: Útil para deixar operações matemáticas de maneira paralela

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

use work.custom_types.all;

entity sum_tree is
generic(
    N_SUMS : natural := 2**6
);
port(
    in_sums : in signed_array(N_SUMS-1 downto 0);
    out_sum : out signed(N_WORD-1 downto 0);
    clk_in : in std_logic;
    reset_in : in std_logic
);
end sum_tree;

architecture Behavioral of sum_tree is
    signal left_sum  : signed(N_WORD-1 downto 0) := (others => '0');
    signal right_sum : signed(N_WORD-1 downto 0) := (others => '0');
    
    signal sum_result : signed(N_WORD-1 downto 0) := (others => '0');
begin

    base_case: if N_SUMS = 2 generate
        sum_result <= in_sums(0) + in_sums(1);
    end generate;

    recursive_gen: if N_SUMS > 2 generate
        left_sums : entity work.sum_tree
            generic map(N_SUMS => N_SUMS/2)
            port map(
                in_sums  => in_sums(N_SUMS-1 downto N_SUMS/2),
                out_sum  => left_sum,
                clk_in   => clk_in,
                reset_in => reset_in
            );

        right_sums : entity work.sum_tree
            generic map(N_SUMS => N_SUMS/2)
            port map(
                in_sums  => in_sums((N_SUMS/2)-1 downto 0),
                out_sum  => right_sum,
                clk_in   => clk_in,
                reset_in => reset_in
            );

        sum_result <= left_sum + right_sum;
    end generate;

    -- Processo de clock controla a saída final
    process(clk_in)
    begin
        if rising_edge(clk_in) then
            if reset_in = '0' then
                out_sum <= (others => '0');
            else
                out_sum <= sum_result;
            end if;
        end if;
    end process;

end architecture Behavioral;
