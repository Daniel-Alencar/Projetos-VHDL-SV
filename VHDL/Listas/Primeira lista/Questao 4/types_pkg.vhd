library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types_pkg is
    subtype my_int is signed(15 downto 0);
    type my_signed_vector is array (natural range <>) of my_int;
end package;
