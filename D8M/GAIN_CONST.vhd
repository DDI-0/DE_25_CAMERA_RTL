-- Module to replace the LPM_CONSTANT(deprecated in QuartusPrimePro(25.3)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GAIN_CONST is
	generic (
		WIDTH  : natural := 14;
		VALUE  : natural := 0
	);
	port (
		result : out std_logic_vector(WIDTH-1 downto 0)
	);
	
	attribute preserve : string;
	attribute preserve of result : signal is "true";
end entity GAIN_CONST;

architecture behavior of GAIN_CONST is
begin
	result <= std_logic_vector(to_unsigned(VALUE, WIDTH));
end architecture behavior;