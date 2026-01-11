library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_read_counter is
    port (
        clk : in  std_logic;
        clr : in  std_logic;
        en  : in  std_logic;
        cnt : out std_logic_vector(15 downto 0)
    );
end entity ram_read_counter;

architecture rtl of ram_read_counter is
    signal cnt_reg : std_logic_vector(15 downto 0) := (others => '0');
begin

    cnt <= cnt_reg;

    process(clk)
        variable cnt_int : integer;
    begin
        if rising_edge(clk) then
            if clr = '0' then
                cnt_reg <= (others => '0');
            elsif en = '1' then
                cnt_int := to_integer(unsigned(cnt_reg)) + 1;
                cnt_reg <= std_logic_vector(to_unsigned(cnt_int, 16));
            end if;
        end if;
    end process;

end architecture rtl;
