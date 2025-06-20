library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_pkg.all;

entity mult_parallel is
    port (
        clk      : in std_logic;
        rst      : in std_logic;
        en       : in std_logic;
        input_v  : in  signed_array(0 to 7);
        output_v : out signed_array(0 to 3)
    );
end entity;

architecture rtl of mult_parallel is
    signal output_reg : signed_array(0 to 3);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                for i in 0 to 3 loop
                    output_reg(i) <= (others => '0');
                end loop;
            elsif en = '1' then
                for i in 0 to 3 loop
                    output_reg(i) <= resize(input_v(2*i), 32) * resize(input_v(2*i+1), 32);
                end loop;
            end if;
        end if;
    end process;

    output_v <= output_reg;

end architecture;
