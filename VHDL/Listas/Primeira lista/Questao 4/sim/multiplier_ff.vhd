library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_pkg.all;

entity tb_multipliers is
end entity;

architecture sim of tb_multipliers is

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal start     : std_logic := '0';

    signal in_vals   : my_signed_vector(0 to 7) := (others => (others => '0'));

    signal out_parallel : my_signed_vector(0 to 3);
    signal out_fsm      : my_signed_vector(0 to 3);
    signal done_fsm     : std_logic;

    constant clk_period : time := 10 ns;

begin

    -- Clock generation
    clk_process : process
    begin
        while now < 2000 ns loop
            clk <= '0'; wait for clk_period / 2;
            clk <= '1'; wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- DUT 1: Paralelo
    uut_parallel : entity work.parallel_multiplier_ff
        port map (
            clk      => clk,
            rst      => rst,
            in_vals  => in_vals,
            out_vals => out_parallel
        );

    -- DUT 2: Sequencial com FSM
    uut_fsm : entity work.fsm_multiplier_ff
        port map (
            clk      => clk,
            rst      => rst,
            start    => start,
            input_a  => in_vals,
            output_y => out_fsm,
            done     => done_fsm
        );

    -- Estímulo de teste
    stimulus : process

        procedure apply_inputs(vec: in my_signed_vector) is
        begin
            -- Reset
            rst <= '1'; start <= '0';
            wait for clk_period;
            rst <= '0';
            in_vals <= vec;

            -- Paralelo já funciona diretamente
            -- Inicia FSM
            start <= '1';
            wait for clk_period;
            start <= '0';

            -- Espera pelo "done"
            wait until done_fsm = '1';

            -- Espera sincronizar com o clock
            wait for clk_period;

            -- Exibe resultado
            report "Inputs: " & 
                   integer'image(to_integer(vec(0))) & ", " &
                   integer'image(to_integer(vec(1))) & ", ..., " &
                   integer'image(to_integer(vec(7)));

            for i in 0 to 3 loop
                report "out_parallel(" & integer'image(i) & ") = " & 
                       integer'image(to_integer(out_parallel(i))) & 
                       " | out_fsm(" & integer'image(i) & ") = " & 
                       integer'image(to_integer(out_fsm(i)));
            end loop;

        end procedure;

    begin
        apply_inputs((
            to_signed(1,16), to_signed(2,16), to_signed(3,16), to_signed(4,16),
            to_signed(5,16), to_signed(6,16), to_signed(7,16), to_signed(8,16)
        ));

        apply_inputs((
            to_signed(0,16), to_signed(9,16), to_signed(-1,16), to_signed(4,16),
            to_signed(10,16), to_signed(-10,16), to_signed(2,16), to_signed(2,16)
        ));

        apply_inputs((
            to_signed(1,16), to_signed(0,16), to_signed(0,16), to_signed(1,16),
            to_signed(1,16), to_signed(1,16), to_signed(1,16), to_signed(1,16)
        ));

        wait for 100 ns;
        report "Simulation completed" severity note;
        wait;
    end process;

end architecture;
