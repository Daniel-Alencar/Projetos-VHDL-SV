library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- MUX e FF
entity mux_ff_top is
    Port (
        clk, ce, rst : in std_logic;
        sel          : in std_logic_vector(1 downto 0);
        a, b, c, d   : in std_logic_vector(7 downto 0);
        q_out        : out std_logic_vector(7 downto 0)
    );
end mux_ff_top;


-- Arquitetura com MUX usando CASE
architecture rtl_case of mux_ff_top is
    signal y : std_logic_vector(7 downto 0);
begin
    mux_inst: entity work.mux4x1_8bit(use_case)
        port map (sel => sel, a => a, b => b, c => c, d => d, y => y);

    dff_inst: entity work.dff_8bit
        port map (clk => clk, ce => ce, rst => rst, d => y, q => q_out);
end rtl_case;

-- Arquitetura com MUX usando IF-ELSIF
architecture rtl_if of mux_ff_top is
    signal y : std_logic_vector(7 downto 0);
begin
    mux_inst: entity work.mux4x1_8bit(use_if)
        port map (sel => sel, a => a, b => b, c => c, d => d, y => y);

    dff_inst: entity work.dff_8bit
        port map (clk => clk, ce => ce, rst => rst, d => y, q => q_out);
end rtl_if;

-- Arquitetura com MUX usando WHEN-ELSE
architecture rtl_when of mux_ff_top is
    signal y : std_logic_vector(7 downto 0);
begin
    mux_inst: entity work.mux4x1_8bit(use_when)
        port map (sel => sel, a => a, b => b, c => c, d => d, y => y);

    dff_inst: entity work.dff_8bit
        port map (clk => clk, ce => ce, rst => rst, d => y, q => q_out);
end rtl_when;

-- Arquitetura com MUX usando WITH-SELECT
architecture rtl_with of mux_ff_top is
    signal y : std_logic_vector(7 downto 0);
begin
    mux_inst: entity work.mux4x1_8bit(use_with)
        port map (sel => sel, a => a, b => b, c => c, d => d, y => y);

    dff_inst: entity work.dff_8bit
        port map (clk => clk, ce => ce, rst => rst, d => y, q => q_out);
end rtl_with;
