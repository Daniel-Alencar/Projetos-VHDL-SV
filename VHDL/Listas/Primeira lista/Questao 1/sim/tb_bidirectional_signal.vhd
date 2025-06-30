library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_bidirectional_signal is
end entity;

architecture sim of tb_bidirectional_signal is
    signal a : std_logic := '0';
    signal b : std_logic := 'Z';
    signal c : std_logic := 'Z';
    signal d : std_logic;

    -- Sinais para simular escrita nos barramentos
    signal b_drive : std_logic := 'Z';
    signal c_drive : std_logic := 'Z';

begin
    uut: entity work.bidirectional_signal
        port map (
            a => a,
            b => b,
            c => c,
            d => d
        );

    -- Simula os sinais bidirecionais
    b <= b_drive when b_drive /= 'Z' else 'Z';
    c <= c_drive when c_drive /= 'Z' else 'Z';

    stim_proc: process
    begin
        -- Teste 1: a = '0' para c envia para b
        report "Teste 1: a = 0 (c para b)" severity note;
        a <= '0';
        c_drive <= '1';    -- Força valor em c
        b_drive <= 'Z';    -- Deixa b ser controlado pela DUT
        wait for 10 ns;
        assert b = '1' report "Erro: b não recebeu c = '1'" severity error;
        assert d = '0' report "Erro: d deveria ser not c = '0'" severity error;

        c_drive <= '0';
        wait for 10 ns;
        assert b = '0' report "Erro: b não recebeu c = '0'" severity error;
        assert d = '1' report "Erro: d deveria ser not c = '1'" severity error;

        -- Teste 2: a = '1' para b envia para c
        report "Teste 2: a = 1 (b para c)" severity note;
        a <= '1';
        b_drive <= '1';    -- Força valor em b
        c_drive <= 'Z';    -- Deixa c ser controlado pela DUT
        wait for 10 ns;
        assert c = '1' report "Erro: c não recebeu b = '1'" severity error;
        assert d = '0' report "Erro: d deveria ser not c = '0'" severity error;

        b_drive <= '0';
        wait for 10 ns;
        assert c = '0' report "Erro: c não recebeu b = '0'" severity error;
        assert d = '1' report "Erro: d deveria ser not c = '1'" severity error;

        report "Testbench finalizado com sucesso." severity note;
        wait;
    end process;

end architecture;
