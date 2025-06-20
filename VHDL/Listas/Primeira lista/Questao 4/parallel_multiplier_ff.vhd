library ieee;
use ieee.std_logic_1164.all;
use work.types_pkg.all;

entity mult_parallel is
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        ce      : in std_logic;
        input_v : in int_array(0 to 7);
        output_v: out int_array(0 to 3)
    );
end entity;

architecture rtl of mult_parallel is
    signal output_reg : int_array(0 to 3);
begin

    -- Saída registrada
    output_v <= output_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                output_reg <= (others => 0);
            elsif ce = '1' then
                for i in 0 to 3 loop
                    output_reg(i) <= input_v(2*i) * input_v(2*i + 1);
                end loop;
            end if;
        end if;
    end process;

end architecture;
