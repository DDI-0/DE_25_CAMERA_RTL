-- reads multiple bytes from slave (address + R bit) after repeated start

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_read_data is
    port (
        reset_n       : in  std_logic;
        pt_ck         : in  std_logic;
        slave_address : in  std_logic_vector(7 downto 0);
        go            : in  std_logic;
        sdai          : in  std_logic;
        sdao          : out std_logic := '1';
        sclo          : out std_logic := '1';
        end_ok        : out std_logic := '1';
        data16        : out std_logic_vector(15 downto 0) := (others=>'0');
        
        st            : out std_logic_vector(7 downto 0);
        ack_ok        : out std_logic := '0';
        cnt           : out std_logic_vector(7 downto 0) := (others=>'0');
        a             : out std_logic_vector(8 downto 0);
        byte          : out std_logic_vector(7 downto 0) := (others=>'0');
        end_byte      : in  std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of i2c_read_data is
    signal state     : integer range 0 to 50 := 0;
    signal del       : unsigned(7 downto 0) := (others=>'0');
    signal bit_cnt   : unsigned(7 downto 0) := (others=>'0');
    signal byte_cnt  : unsigned(7 downto 0) := (others=>'0');
    signal data_reg  : std_logic_vector(15 downto 0) := (others=>'0');
    signal addr_reg  : std_logic_vector(8 downto 0) := (others=>'0');
begin
    st     <= std_logic_vector(to_unsigned(state, 8));
    cnt    <= std_logic_vector(bit_cnt);
    byte   <= std_logic_vector(byte_cnt);
    a      <= addr_reg;
    data16 <= data_reg;

    process(pt_ck)
    begin
        if rising_edge(pt_ck) then
            if reset_n = '0' then
                state     <= 0;
                sdao      <= '1';
                sclo      <= '1';
                end_ok    <= '1';
                ack_ok    <= '0';
                bit_cnt   <= (others=>'0');
                byte_cnt  <= (others=>'0');
                del       <= (others=>'0');
                data_reg  <= (others=>'0');
                addr_reg  <= (others=>'0');
            else
                case state is
                    when 0 =>
                        sdao   <= '1';
                        sclo   <= '1';
                        ack_ok <= '0';
                        bit_cnt<= (others=>'0');
                        end_ok <= '1';
                        byte_cnt<=(others=>'0');
                        data_reg<=(others=>'0');
                        if go = '1' then
                            state <= 30;
                        end if;

                    when 1 =>
                        state   <= 2;
                        sdao    <= '0';
                        sclo    <= '1';
                        addr_reg <= slave_address & '1';

                    when 2 =>
                        state <= 3;
                        sclo  <= '0';

                    when 3 =>
                        state    <= 4;
                        sdao     <= addr_reg(8);
                        addr_reg <= addr_reg(7 downto 0) & '0';

                    when 4 =>
                        state   <= 5;
                        sclo    <= '1';
                        bit_cnt <= bit_cnt + 1;

                    when 5 =>
                        sclo <= '0';
                        if bit_cnt = 9 then
                            state  <= 6;
                            ack_ok <= not sdai;
                        else
                            state <= 2;
                        end if;

                    when 6 =>
                        state   <= 7;
                        sdao    <= '1';
                        sclo    <= '0';
                        bit_cnt <= (others=>'0');

                    when 7 =>
                        state   <= 8;
                        del     <= (others=>'0');
                        sclo    <= '1';
                        if bit_cnt /= 8 then
                            data_reg <= data_reg(14 downto 0) & sdai;
                        end if;
                        bit_cnt <= bit_cnt + 1;

                    when 8 =>
                        del  <= del + 1;
                        sclo <= '0';
                        if del = 2 then
                            if bit_cnt = 8 then
                                state <= 7;
                                if byte_cnt = unsigned(end_byte) then
                                    sdao <= '1';
                                else
                                    sdao <= '0';
                                end if;
                            elsif bit_cnt = 9 then
                                byte_cnt <= byte_cnt + 1;
                                state    <= 9;
                            else
                                state <= 7;
                            end if;
                        end if;

                    when 9 =>
                        if byte_cnt > unsigned(end_byte) then
                            state <= 10;
                        else
                            state <= 6;
                        end if;

                    when 10 =>
                        state <= 11;
                        sdao  <= '0';
                        sclo  <= '0';

                    when 11 =>
                        state <= 12;
                        sdao  <= '0';
                        sclo  <= '1';

                    when 12 =>
                        state <= 13;
                        sdao  <= '1';
                        sclo  <= '1';

                    when 13 =>
                        state    <= 30;
                        end_ok   <= '1';
                        sdao     <= '1';
                        sclo     <= '1';
                        ack_ok   <= '0';
                        bit_cnt  <= (others=>'0');
                        byte_cnt <= (others=>'0');

                    when 30 =>
                        if go = '0' then
                            state <= 31;
                        end if;

                    when 31 =>
                        end_ok <= '0';
                        state  <= 1;

                    when others =>
                        state <= 0;
                end case;
            end if;
        end if;
    end process;
end architecture;