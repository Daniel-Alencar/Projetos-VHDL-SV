library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Importa N_WORD e signed_array
use work.custom_types.all;

entity sum_tree_for is
    generic(
        N_INPUTS: natural := 2**6
    );
    port(
        -- Entradas de valores
        in_sums: in signed_array(N_INPUTS-1 downto 0);
        -- O resultado da soma
        out_sum: out signed(N_WORD-1 downto 0);
        clk_in: in std_logic;
        reset_in: in std_logic
    );
end sum_tree_for;

architecture Behavorial of sum_tree_for is

    -- Função de log2 para o cálculo dinâmico da quantidade de níveis
    -- de acordo com o número de inputs
    function log2(n: integer) return integer is
        variable rest: integer := 0;
        variable value: integer := n;
    begin
        while value > 1 loop
            value := value / 2;
            rest := rest + 1;
        end loop;
        return rest;
    end;

    -- Quantidade de níveis com somas paralelas
    constant N_LEVELS : natural := log2(N_INPUTS);
    
    -- Matriz com os resultados de cada soma em cada nível
    type matrix is array (0 to N_LEVELS) of signed_array(0 to N_INPUTS-1);
    signal sums_matrix : matrix := (others => (others => (others => '0')));
begin

    -- Assert para garantir uma quantidade de inputs válida
    assert (N_INPUTS mod 2 = 0)
        report "Number of sums must be power of two"
        severity failure;

    -- Atribuição inicial dos dados de entrada
    sums_matrix(0) <= in_sums;

    -- Soma paralela por nível
    level_generate: for i in 1 to N_LEVELS generate
        -- N_INPUTS / (2**i) representa a quantidade de somadores que haverão em cada nível
        adder_generate: for j in 0 to ((N_INPUTS / (2**i))-1) generate

            -- Representa a soma sendo realizada por nível
            -- Cada soma deste nível é realizada em paralelo
            process(clk_in)
            begin
                if rising_edge(clk_in) then
                    if reset_in = '0' then
                        -- Se o reset é pressionado, os valores de soma daquele nível
                        -- vão para 0
                        sums_matrix(i)(j) <= (others => '0');
                    else
                        -- Soma dos valores do nível anterior e armazenamento do valor em 
                        -- um slot do nível atual
                        sums_matrix(i)(j) <= sums_matrix(i-1)(2*j) + sums_matrix(i-1)(2*j+1);
                    end if;
                end if;
            end process;

        end generate adder_generate;
    end generate level_generate;

    out_sum <= sums_matrix(N_LEVELS)(0);
end architecture Behavorial;