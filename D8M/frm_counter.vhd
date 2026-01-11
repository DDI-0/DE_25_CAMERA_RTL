library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity frm_counter is
  port (
    clock : in  std_logic;
    clr   : in  std_logic;
    de    : in  std_logic;
    addr  : out std_logic_vector(19 downto 0)
  );
end entity frm_counter;

architecture rtl of frm_counter is
  signal rclr : std_logic := '0';
  signal cnt  : unsigned(19 downto 0) := (others => '0');
begin

  process(clock)
  begin
    if rising_edge(clock) then
      rclr <= clr;

      if rclr = '0' and clr = '1' then     -- rising edge of clr
        cnt <= (others => '0');
      elsif de = '1' then
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  addr <= std_logic_vector(cnt);

end architecture rtl;