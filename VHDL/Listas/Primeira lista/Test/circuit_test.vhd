library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity circuito_test is
    Port (
        a : in STD_LOGIC;
        b : in STD_LOGIC;
        y : out STD_LOGIC
    );
end circuito_test;

architecture Behavioral of circuito_test is
begin
    y <= a AND b;
end Behavioral;
