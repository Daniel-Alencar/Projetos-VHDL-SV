library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.types_pkg.all;

entity tb_mult is
end tb_mult;

architecture sim of tb_mult is

    -- Clock & controle
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal ce    : std_logic := '0';
    signal done  : std_logic;

    -- Entrada e saída
    signal input_v        : int_array(0 to 7);
    signal output_par     : int_array(0 to 3);
    signal output_seq     : int_array(0 to 3);

    -- Clock period
    constant clk_period : time := 10 ns;

begin

    -- Clock generation
    clk_proc : process
    begin
        while now < 1000 ns loop
            clk <= '0'; wait for clk_period / 2;
            clk <= '1'; wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- DUT: Versão paralela
    dut_par : entity work.mult_parallel
        port map (
            clk      => clk,
            rst      => rst,
            ce       => ce,
            input_v  => input_v,
            output_v => output_par
        );

    -- DUT: Versão sequencial
    dut_seq : entity work.mult_sequencial
        port map (
            clk      => clk,
            rst      => rst,
            ce       => ce,
            input_v  => input_v,
            output_v => output_seq,
            done     => done
        );

    -- Estímulo
    stim_proc : process
    begin
        rst <= '1'; ce <= '0'; wait for clk_period;
        rst <= '0'; ce <= '1';

        -- CASO DE TESTE 1
        input_v <= (1, 2, 3, 4, 5, 6, 7, 8);
        wait for clk_period;

        -- Aguarda cálculo sequencial terminar
        wait until done = '1';
        wait for clk_period;

        -- Comparação
        report "=== TESTE 1 ===";
        for i in 0 to 3 loop
            if output_par(i) = output_seq(i) then
                report "OK: saída(" & integer'image(i) & ") = " & integer'image(output_par(i));
            else
                report "ERRO: saída(" & integer'image(i) & ") paralela=" &
                    integer'image(output_par(i)) & ", sequencial=" &
                    integer'image(output_seq(i))
                    severity error;
            end if;
        end loop;

        -- CASO DE TESTE 2
        rst <= '1'; wait for clk_period;
        rst <= '0';

        input_v <= (10, 20, -3, 7, 0, 100, -8, -1);
        wait for clk_period;

        wait until done = '1';
        wait for clk_period;

        report "=== TESTE 2 ===";
        for i in 0 to 3 loop
            if output_par(i) = output_seq(i) then
                report "OK: saída(" & integer'image(i) & ") = " & integer'image(output_par(i));
            else
                report "ERRO: saída(" & integer'image(i) & ") paralela=" &
                    integer'image(output_par(i)) & ", sequencial=" &
                    integer'image(output_seq(i))
                    severity error;
            end if;
        end loop;

        report "Fim da simulação";
        wait;
    end process;

end architecture;
