library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--===========================--
-- Top-level: MUX + FF      --
--===========================--
entity mux_ff_top is
    Port (
        clk, ce, rst : in std_logic;
        sel          : in std_logic_vector(1 downto 0);
        a, b, c, d   : in std_logic_vector(7 downto 0);
        q_out        : out std_logic_vector(7 downto 0)
    );
end mux_ff_top;

architecture rtl of mux_ff_top is
    signal y_case_selected : std_logic_vector(7 downto 0);
    signal y_if_selected : std_logic_vector(7 downto 0);
    signal y_when_selected : std_logic_vector(7 downto 0);
    signal y_with_selected : std_logic_vector(7 downto 0);
begin

    -- Mux usando uma arquitetura "use_with"
    mux_inst: entity work.mux4x1_8bit(use_with)
        port map (
            sel     => sel,
            a       => a,
            b       => b,
            c       => c,
            d       => d,
            y_case  => y_case_selected,
            y_if    => y_if_selected,
            y_when  => y_when_selected,
            y_with  => y_with_selected
        );

    -- Flip-flop D
    dff_inst: entity work.dff_8bit
        port map (
            clk => clk,
            ce  => ce,
            rst => rst,
            d   => y_case_selected,
            q   => q_out
        );

end rtl;
