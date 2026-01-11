library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_delay is
    port (
        reset_n : in  std_logic;
        clk     : in  std_logic;
        ready0  : out std_logic;
        ready1  : out std_logic
    );
end entity reset_delay;

architecture rtl of reset_delay is
    constant time_val : integer := 50000000;
    signal delay      : std_logic_vector(31 downto 0) := (others => '0');
    signal ready0_reg : std_logic := '0';
    signal ready1_reg : std_logic := '0';
begin

    ready0 <= ready0_reg;
    ready1 <= ready1_reg;

    process(clk)
        variable delay_int : integer;
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                delay       <= (others => '0');
                ready0_reg  <= '0';
                ready1_reg  <= '0';
            else
                delay_int := to_integer(unsigned(delay));
                if delay_int < time_val then
                    delay_int := delay_int + 1;
                    delay <= std_logic_vector(to_unsigned(delay_int, 32));
                end if;
                if delay_int = time_val / 4 then
                    ready0_reg <= '1';
                end if;
                if delay_int = time_val / 2 then
                    ready1_reg <= '1';
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
