library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fps_monitor is
  port (
    clk50      : in  std_logic;
    vs         : in  std_logic;
    fps        : out std_logic_vector(7 downto 0);
    hex_fps_h  : out std_logic_vector(6 downto 0);
    hex_fps_l  : out std_logic_vector(6 downto 0)
  );
end entity fps_monitor;

architecture rtl of fps_monitor is

  constant ONE_SEC     : unsigned(31 downto 0) := to_unsigned(50000000, 32);
  constant ALMOST_ONE  : unsigned(26 downto 0) := to_unsigned(49999999, 27);

  signal sec_cnt       : unsigned(26 downto 0) := (others => '0');
  signal pre_vs        : std_logic := '0';
  signal frame_cnt     : unsigned(7 downto 0)  := (others => '0');
  signal bcd_l         : unsigned(3 downto 0)  := (others => '0');
  signal bcd_h         : unsigned(3 downto 0)  := (others => '0');
  signal fps_reg       : std_logic_vector(7 downto 0);

  signal one_sec_pulse : std_logic;

begin

  one_sec_pulse <= '1' when sec_cnt >= ALMOST_ONE else '0';

  process(clk50)
  begin
    if rising_edge(clk50) then
      if one_sec_pulse = '1' then
        sec_cnt <= (others => '0');
      else
        sec_cnt <= sec_cnt + 1;
      end if;
    end if;
  end process;

  process(clk50)
  begin
    if rising_edge(clk50) then
      pre_vs <= vs;

      if one_sec_pulse = '1' then
        frame_cnt <= (others => '0');
        bcd_h     <= (others => '0');
        bcd_l     <= (others => '0');
      elsif pre_vs = '0' and vs = '1' then
        frame_cnt <= frame_cnt + 1;

        if bcd_l = 9 then
          bcd_l <= (others => '0');
          bcd_h <= bcd_h + 1;
        else
          bcd_l <= bcd_l + 1;
        end if;
      end if;
    end if;
  end process;

  process(clk50)
  begin
    if rising_edge(clk50) then
      if one_sec_pulse = '1' then
        fps_reg <= std_logic_vector(frame_cnt);
      end if;
    end if;
  end process;

  fps <= fps_reg;

  hex_fps_h <= "1000000" when bcd_h = 0 else
               "1111001" when bcd_h = 1 else
               "0100100" when bcd_h = 2 else
               "0110000" when bcd_h = 3 else
               "0011001" when bcd_h = 4 else
               "0010010" when bcd_h = 5 else
               "0000010" when bcd_h = 6 else
               "1111000" when bcd_h = 7 else
               "0000000" when bcd_h = 8 else
               "0010000";

  hex_fps_l <= "1000000" when bcd_l = 0 else
               "1111001" when bcd_l = 1 else
               "0100100" when bcd_l = 2 else
               "0110000" when bcd_l = 3 else
               "0011001" when bcd_l = 4 else
               "0010010" when bcd_l = 5 else
               "0000010" when bcd_l = 6 else
               "1111000" when bcd_l = 7 else
               "0000000" when bcd_l = 8 else
               "0010000";

end architecture rtl;