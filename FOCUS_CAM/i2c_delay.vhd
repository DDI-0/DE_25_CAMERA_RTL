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

architecture behavior of i2c_delay is
  signal delay : unsigned(31 downto 0) := (others => '0');
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        delay <= (others => '0');
        ready <= '0';
      else
        if delay < 150 then          -- 30 * 5
          delay <= delay + 1;
        else
          ready <= '1';
        end if;
      end if;
    end if;
  end process;
end architecture behavior;