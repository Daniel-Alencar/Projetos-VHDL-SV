library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--====================--
-- Entidade do MUX   --
--====================--
entity mux4x1_8bit is
    Port (
        sel        : in std_logic_vector(1 downto 0);
        a, b, c, d : in std_logic_vector(7 downto 0);
        y          : out std_logic_vector(7 downto 0)
    );
end mux4x1_8bit;

architecture use_case of mux4x1_8bit is
begin
    process(sel, a, b, c, d)
    begin
        case sel is
            when "00" => y <= a;
            when "01" => y <= b;
            when "10" => y <= c;
            when others => y <= d;
        end case;
    end process;
end use_case;

architecture use_if of mux4x1_8bit is
begin
    process(sel, a, b, c, d)
    begin
        if sel = "00" then
            y <= a;
        elsif sel = "01" then
            y <= b;
        elsif sel = "10" then
            y <= c;
        else
            y <= d;
        end if;
    end process;
end use_if;

architecture use_when of mux4x1_8bit is
begin
    y <= a when sel = "00" else
         b when sel = "01" else
         c when sel = "10" else
         d;
end use_when;

architecture use_with of mux4x1_8bit is
begin
    with sel select
        y <= a when "00",
             b when "01",
             c when "10",
             d when others;
end use_with;
