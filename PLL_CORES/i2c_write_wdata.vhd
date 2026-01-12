-- writes slave address + 16-bit pointer + 16-bit data
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_write_wdata is
    port (
        reset_n        : in  std_logic;
        pt_ck          : in  std_logic;
        go             : in  std_logic;
        light_int      : in  std_logic;
        pointer        : in  std_logic_vector(15 downto 0);
        slave_address  : in  std_logic_vector(7 downto 0);
        wdata          : in  std_logic_vector(15 downto 0);
        sdai           : in  std_logic;
        sdao           : out std_logic;
        sclo           : out std_logic;
        end_ok         : out std_logic;
        -- test outputs
        sdai_w         : out std_logic;
        st             : out std_logic_vector(7 downto 0);
        cnt            : out std_logic_vector(7 downto 0);
        byte           : out std_logic_vector(7 downto 0);
        ack_ok         : out std_logic;
        byte_num       : in  std_logic_vector(7 downto 0) 
    );
end entity i2c_write_wdata;

architecture rtl of i2c_write_wdata is

    signal st_reg     : unsigned(7 downto 0);
    signal cnt_reg    : unsigned(7 downto 0);
    signal byte_reg   : unsigned(7 downto 0);
    signal a_reg      : std_logic_vector(8 downto 0);
    signal dely_reg   : unsigned(7 downto 0);
    signal sdao_reg   : std_logic;
    signal sclo_reg   : std_logic;
    signal end_ok_reg : std_logic;
    signal ack_ok_reg : std_logic;

begin

    sdai_w  <= sdai;
    st      <= std_logic_vector(st_reg);
    cnt     <= std_logic_vector(cnt_reg);
    byte    <= std_logic_vector(byte_reg);
    ack_ok  <= ack_ok_reg;
    sdao    <= sdao_reg;
    sclo    <= sclo_reg;
    end_ok  <= end_ok_reg;

    process(pt_ck)
    begin
        if rising_edge(pt_ck) then
            if reset_n = '0' then
                st_reg     <= (others => '0');
                cnt_reg    <= (others => '0');
                byte_reg   <= (others => '0');
                a_reg      <= (others => '0');
                dely_reg   <= (others => '0');
                sdao_reg   <= '1';
                sclo_reg   <= '1';
                end_ok_reg <= '1';
                ack_ok_reg <= '0';
            else
                case to_integer(st_reg) is
                    when 0 =>                   -- idle / init
                        sdao_reg   <= '1';
                        sclo_reg   <= '1';
                        ack_ok_reg <= '0';
                        cnt_reg    <= (others => '0');
                        end_ok_reg <= '1';
                        byte_reg   <= (others => '0');
                        if go = '1' then
                            st_reg <= to_unsigned(30, 8);
                        end if;

                    when 1 =>                   -- generate start
                        st_reg   <= to_unsigned(2,8);
                        sdao_reg <= '0';
                        sclo_reg <= '1';
                        a_reg    <= slave_address & '1';  -- write

                    when 2 =>
                        st_reg   <= to_unsigned(3,8);
                        sdao_reg <= '0';
                        sclo_reg <= '0';

                    when 3 =>
                        st_reg   <= to_unsigned(4,8);
                        sdao_reg <= a_reg(8);
                        a_reg    <= a_reg(7 downto 0) & '0';

                    when 4 =>
                        st_reg   <= to_unsigned(5,8);
                        sclo_reg <= '1';
                        cnt_reg  <= cnt_reg + 1;

                    when 5 =>
                        sclo_reg <= '0';
                        if cnt_reg = 9 then
                            -- sample ack
                            if sdai = '0' then
                                ack_ok_reg <= '1';
                            else
                                ack_ok_reg <= '0';
                            end if;

                            if byte_reg = unsigned(byte_num) then
                                st_reg <= to_unsigned(6,8);     -- all bytes sent → stop
                            else
                                cnt_reg <= (others => '0');
                                st_reg  <= to_unsigned(2,8);
                                case to_integer(byte_reg) is
                                    when 0 =>
                                        byte_reg <= to_unsigned(1,8);
                                        a_reg <= pointer(15 downto 8) & '1';
                                    when 1 =>
                                        byte_reg <= to_unsigned(2,8);
                                        a_reg <= pointer(7 downto 0) & '1';
                                    when 2 =>
                                        byte_reg <= to_unsigned(3,8);
                                        a_reg <= wdata(15 downto 8) & '1';
                                    when 3 =>
                                        byte_reg <= to_unsigned(4,8);
                                        a_reg <= wdata(7 downto 0) & '1';
                                    when others =>
                                        null;
                                end case;
                            end if;
                        else
                            st_reg <= to_unsigned(2,8);
                        end if;

                    when 6 =>                   -- stop condition
                        st_reg   <= to_unsigned(7,8);
                        sdao_reg <= '0';
                        sclo_reg <= '0';

                    when 7 =>
                        st_reg   <= to_unsigned(8,8);
                        sdao_reg <= '0';
                        sclo_reg <= '1';

                    when 8 =>
                        st_reg   <= to_unsigned(9,8);
                        sdao_reg <= '1';
                        sclo_reg <= '1';

                    when 9 =>                   -- stop completed
                        st_reg     <= to_unsigned(30,8);
                        sdao_reg   <= '1';
                        sclo_reg   <= '1';
                        ack_ok_reg <= '0';
                        cnt_reg    <= (others => '0');
                        end_ok_reg <= '1';
                        byte_reg   <= (others => '0');

                    when 30 =>                  -- wait for go low
                        if go = '0' then
                            st_reg <= to_unsigned(31,8);
                        end if;

                    when 31 =>                  -- trigger transaction
                        end_ok_reg <= '0';
                        st_reg     <= to_unsigned(1,8);

                    -- sleep/unknown states removed or kept minimal
                    when others =>
                        st_reg <= (others => '0');

                end case;
            end if;
        end if;
    end process;

end architecture rtl;