library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_delay is
    port (
        reset_n : in  std_logic;
        clk     : in  std_logic;
        ready   : out std_logic
    );
end entity i2c_delay;

architecture rtl of i2c_delay is
    constant time_val : unsigned(31 downto 0) := to_unsigned(30*5, 32);
    signal delay      : unsigned(31 downto 0) := (others => '0');
    signal ready_reg  : std_logic := '0';
begin

    ready <= ready_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                delay     <= (others => '0');
                ready_reg <= '0';
            else
                if delay < time_val then
                    delay <= delay + 1;
                else
                    ready_reg <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
