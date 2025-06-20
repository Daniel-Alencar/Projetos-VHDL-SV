library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_pkg.all;

entity mult_sequencial is
    port (
        clk      : in std_logic;
        rst      : in std_logic;
        ce       : in std_logic;
        input_v  : in int_array(0 to 7);
        output_v : out int_array(0 to 3);
        done     : out std_logic  -- Sinaliza fim das multiplicações
    );
end entity;

architecture rtl of mult_sequencial is
    type state_type is (IDLE, LOAD, CALC, FINISH);
    signal state, next_state : state_type;

    signal output_reg : int_array(0 to 3);
    signal i          : integer range 0 to 3 := 0;

begin

    output_v <= output_reg;
    done     <= '1' when state = FINISH else '0';

    -- Máquina de estados: transições
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
            elsif ce = '1' then
                state <= next_state;
            end if;
        end if;
    end process;

    -- Lógica da FSM
    process(state, i)
    begin
        case state is
            when IDLE =>
                next_state <= LOAD;

            when LOAD =>
                next_state <= CALC;

            when CALC =>
                if i = 3 then
                    next_state <= FINISH;
                else
                    next_state <= CALC;
                end if;

            when FINISH =>
                next_state <= FINISH;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

    -- Operações síncronas
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                output_reg <= (others => 0);
                i <= 0;
            elsif ce = '1' then
                case state is
                    when LOAD =>
                        i <= 0;

                    when CALC =>
                        output_reg(i) <= input_v(2*i) * input_v(2*i + 1);
                        i <= i + 1;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

end architecture;
