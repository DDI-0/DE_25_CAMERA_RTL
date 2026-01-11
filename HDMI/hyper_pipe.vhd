library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hyper_pipe is
    generic (
        WIDTH     : integer := 2;
        NUM_PIPES : integer := 2
    );
    port (
        clk  : in  std_logic;
        din  : in  std_logic_vector(WIDTH-1 downto 0);
        dout : out std_logic_vector(WIDTH-1 downto 0)
    );
	 
	     -- Altera attribute (Quartus)
    attribute altera_attribute : string;
    attribute altera_attribute of hyper_pipe : entity is
        "-name AUTO_SHIFT_REGISTER_RECOGNITION off";

end entity hyper_pipe;

architecture rtl of hyper_pipe is
    -- Array of pipeline registers
    type hp_array_t is array (natural range <>) of
        std_logic_vector(WIDTH-1 downto 0);

    signal hp : hp_array_t(0 to NUM_PIPES-1);

begin

    -- Case: no pipeline stages
    gen_no_pipe : if NUM_PIPES = 0 generate
        dout <= din;
    end generate;

    -- Case: one or more pipeline stages
    gen_pipe : if NUM_PIPES > 0 generate

        -- First pipeline register
        process (clk)
        begin
            if rising_edge(clk) then
                hp(0) <= din;
            end if;
        end process;

        -- Remaining pipeline registers
        gen_regs : for i in 1 to NUM_PIPES-1 generate
            process (clk)
            begin
                if rising_edge(clk) then
                    hp(i) <= hp(i-1);
                end if;
            end process;
        end generate;

        dout <= hp(NUM_PIPES-1);
    end generate;
end architecture rtl;
