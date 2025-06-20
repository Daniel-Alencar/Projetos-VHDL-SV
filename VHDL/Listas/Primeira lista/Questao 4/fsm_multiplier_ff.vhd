library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_pkg.all;

entity fsm_multiplier_ff is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        start    : in  std_logic;
        input_a  : in  my_signed_vector(0 to 7);
        output_y : out my_signed_vector(0 to 3);
        done     : out std_logic
    );
end entity;

architecture rtl of fsm_multiplier_ff is

    type state_type is (idle, load, calc, finish);
    signal state      : state_type := idle;

    signal index      : integer range 0 to 3 := 0;
    signal temp_out   : my_signed_vector(0 to 3);
    signal done_int   : std_logic := '0';

    signal a, b       : signed(15 downto 0);
    -- resultado da multiplicação
    signal result     : signed(63 downto 0);

begin

    done     <= done_int;
    output_y <= temp_out;

    process(clk, rst)
        variable a, b       : signed(31 downto 0);
        variable result     : signed(63 downto 0);
    begin
        if rst = '1' then
            state     <= idle;
            index     <= 0;
            temp_out  <= (others => (others => '0'));
            done_int  <= '0';

        elsif rising_edge(clk) then
            case state is

                when idle =>
                    done_int <= '0';
                    if start = '1' then
                        index <= 0;
                        state <= load;
                    end if;

                when load =>
                    state <= calc;

                when calc =>
                    a := resize(input_a(2*index), 32);
                    b := resize(input_a(2*index + 1), 32);
                    result := a * b;
                    
                    -- Pega apenas 16 bits
                    temp_out(index) <= result(15 downto 0);
                    if index = 3 then
                        state <= finish;
                    else
                        index <= index + 1;
                        state <= load;
                    end if;

                when finish =>
                    done_int <= '1';
                    state <= idle;

            end case;
        end if;
    end process;

end architecture;
