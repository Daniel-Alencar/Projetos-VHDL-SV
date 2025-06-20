library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_counters is
end entity;

architecture sim of tb_counters is
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';

    signal out_int : integer range -128 to 127;
    signal out_signed : signed(7 downto 0);
    signal out_unsigned : unsigned(7 downto 0);
begin

    -- Clock de 10 ns
    clk_process : process
    begin
        while now < 5000 ns loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Reset
    reset_process : process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait;
    end process;

    -- Instanciando contadores
    int_inst : entity work.integer_counter
        port map (
            clk => clk,
            reset => reset,
            output => out_int
        );

    signed_inst : entity work.signed_counter
        port map (
            clk => clk,
            reset => reset,
            output => out_signed
        );

    unsigned_inst : entity work.unsigned_counter
        port map (
            clk => clk,
            reset => reset,
            output => out_unsigned
        );

end architecture;
