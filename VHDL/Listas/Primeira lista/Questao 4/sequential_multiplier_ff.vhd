library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_pkg.all;

entity sequential_multiplier_ff is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        in_vals  : in  my_integer_vector(0 to 7);
        out_vals : out my_integer_vector(0 to 3)
    );
end entity;

architecture rtl of sequential_multiplier_ff is

    -- FFs para armazenar os resultados
    signal ff_outputs : my_integer_vector(0 to 3) := (others => 0);

    -- Índice de multiplicação atual (0 a 3)
    signal index : integer range 0 to 3 := 0;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            ff_outputs <= (others => 0);
            index <= 0;

        elsif rising_edge(clk) then
            -- Executa apenas uma multiplicação por ciclo
            ff_outputs(index) <= in_vals(2 * index) * in_vals(2 * index + 1);

            -- Atualiza índice (circular)
            if index = 3 then
                index <= 0;
            else
                index <= index + 1;
            end if;
        end if;
    end process;

    -- Saída
    out_vals <= ff_outputs;

end architecture;
