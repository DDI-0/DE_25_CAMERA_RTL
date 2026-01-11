library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_controller is
	port (
		clk			: in    std_logic;
		reset_n		: in    std_logic;
		
		i2c_frame	: in    std_logic_vector(23 downto 0); -- (7-bit slave_addr + R/W) + (8-bit register_addr) + (8-bit data)
		i2c_sda	   : inout std_logic;
		i2c_scl		: out   std_logic;
		i2c_RW		: in    std_logic;
		i2c_start   : in    std_logic;
		i2c_stop	   : out   std_logic;
		i2c_ack		: out   std_logic;
		
		-- test
		i2c_bit_cnt : out   std_logic_vector(5 downto 0);
		i2c_sda_out : out   std_logic	
	);
end entity i2c_controller;

architecture rtl of i2c_controller is
	signal scl	: std_logic	:= '1';
	signal frame	: std_logic_vector(23 downto 0):= (others => '0');
	signal bit_cnt : std_logic_vector(5 downto 0) := (others => '1');
	signal sda_out	: std_logic := '1';
	signal stop		: std_logic := '1'; -- idle state
	signal ack_1, ack_2, ack_3 : std_logic := '0';
	signal active_window : std_logic;
	
	constant MAX_COUNTER : std_logic_vector(bit_cnt'range) := (others => '1'); 
	
begin

	-- output assignments
	active_window <= '1' when unsigned(bit_cnt) >= 4 AND unsigned(bit_cnt) <= 30 else '0';
	i2c_scl 		  <= scl OR ( (NOT clk AND active_window));
	i2c_sda       <= 'Z' when sda_out = '1' else '0';
	i2c_stop	     <= stop;
	i2c_bit_cnt   <= bit_cnt;
	i2c_sda_out   <= sda_out;
	i2c_ack       <= ack_1 OR ack_2 OR ack_3;
	
	-- counter process
		process(clk)
		begin
			if rising_edge(clk) then
				if reset_n = '0' then
					bit_cnt <= (others => '1'); -- reset to 63
				elsif i2c_start = '0' then
					bit_cnt <= (others => '0'); -- start from 0
				elsif unsigned(bit_cnt) < unsigned(MAX_COUNTER) then
					bit_cnt <= std_logic_vector(unsigned(bit_cnt) + 1);
				end if;
			end if;
		end process;
		
	-- i2c logic
		process(clk)
		begin
			if rising_edge(clk) then
				if reset_n = '0' then
					scl 	<= '1';
					sda_out  <= '1';
					ack_1		<= '0';
					ack_2		<= '0';
					ack_3		<= '0';
					stop	   <= '1';
				else
					case bit_cnt is
						when "000000" =>
							ack_1 	<= '0'; 
							ack_2	   <= '0'; 
							ack_3 	<= '0';
							stop  	<= '0';
							sda_out 	<= '1';
							scl  <= '1';
						when "000001" =>
							frame 	<= i2c_frame;
							sda_out  <= '0';
						when "000010" =>
							scl <= '0';
						-- slave addr
						when "000011" => sda_out <= frame(23);
						when "000100" => sda_out <= frame(22);
						when "000101" => sda_out <= frame(21);
						when "000110" => sda_out <= frame(20);
						when "000111" => sda_out <= frame(19);
					   when "001000" => sda_out <= frame(18);
						when "001001" => sda_out <= frame(17);
						when "001010" => sda_out <= frame(16);
						when "001011" => sda_out <= '1'; -- ACK
						-- sub addr
						when "001100" =>
							sda_out <= frame(15);
                     ack_1   <= i2c_sda;
                 when "001101" => sda_out <= frame(14);
                 when "001110" => sda_out <= frame(13);
                 when "001111" => sda_out <= frame(12);
                 when "010000" => sda_out <= frame(11);
                 when "010001" => sda_out <= frame(10);
                 when "010010" => sda_out <= frame(9);
                 when "010011" => sda_out <= frame(8);
                 when "010100" => sda_out <= '1'; -- ACK
					  -- Data 
					  when "010101" =>
                    sda_out <= frame(7);
                    ack_2   <= i2c_sda;
                 when "010110" => sda_out <= frame(6);
                 when "010111" => sda_out <= frame(5);
                 when "011000" => sda_out <= frame(4);
                 when "011001" => sda_out <= frame(3);
                 when "011010" => sda_out <= frame(2);
                 when "011011" => sda_out <= frame(1);
                 when "011100" => sda_out <= frame(0);
                 when "011101" => sda_out <= '1'; -- ACK
			        -- Stop
					  when "011110" =>
                    sda_out <= '0';
                    scl <= '0';
                    ack_3 <= i2c_sda;
                 when "011111" =>
                    scl <= '1';
                 when "100000" =>
                    sda_out <= '1';
                    stop <= '1';
                 when others =>
						null;
				end case;
			end if;
		end if;
	end process;
end architecture rtl;