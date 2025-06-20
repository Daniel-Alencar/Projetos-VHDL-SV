library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Define o tipo do vetor de barramento
package mux_pkg is
    type slv8_array16 is array (0 to 15) of std_logic_vector(7 downto 0);
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mux_pkg.all;

entity mux_ff_quad_top is
    port (
        clk        : in std_logic;
        ce         : in std_logic;
        rst        : in std_logic;
        sel        : in std_logic_vector(1 downto 0);
        bus_array  : in slv8_array16;
        q_case     : out std_logic_vector(7 downto 0);
        q_if       : out std_logic_vector(7 downto 0);
        q_when     : out std_logic_vector(7 downto 0);
        q_with     : out std_logic_vector(7 downto 0)
    );
end mux_ff_quad_top;

architecture rtl of mux_ff_quad_top is
begin

    -- MUX com CASE
    mux_case_inst: entity work.mux_ff_top(rtl_case)
        port map (
            clk => clk, ce => ce, rst => rst,
            sel => sel,
            a => bus_array(0),
            b => bus_array(4),
            c => bus_array(8),
            d => bus_array(12),
            q_out => q_case
        );

    -- MUX com IF
    mux_if_inst: entity work.mux_ff_top(rtl_if)
        port map (
            clk => clk, ce => ce, rst => rst,
            sel => sel,
            a => bus_array(1),
            b => bus_array(5),
            c => bus_array(9),
            d => bus_array(13),
            q_out => q_if
        );

    -- MUX com WHEN-ELSE
    mux_when_inst: entity work.mux_ff_top(rtl_when)
        port map (
            clk => clk, ce => ce, rst => rst,
            sel => sel,
            a => bus_array(2),
            b => bus_array(6),
            c => bus_array(10),
            d => bus_array(14),
            q_out => q_when
        );

    -- MUX com WITH-SELECT
    mux_with_inst: entity work.mux_ff_top(rtl_with)
        port map (
            clk => clk, ce => ce, rst => rst,
            sel => sel,
            a => bus_array(3),
            b => bus_array(7),
            c => bus_array(11),
            d => bus_array(15),
            q_out => q_with
        );

end rtl;
