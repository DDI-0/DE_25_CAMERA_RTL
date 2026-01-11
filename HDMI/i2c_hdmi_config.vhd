library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_hdmi_config is
    port (
        clk         : in  std_logic;                    
        reset_n     : in  std_logic;                    
        i2c_sda     : inout std_logic;
        i2c_scl     : out std_logic;
        hdmi_tx_int : in  std_logic;                    -- HDMI_TX_INT (active low)
        config_done : out std_logic                     -- High when configuration complete
    );
end entity;

architecture rtl of i2c_hdmi_config is
	  component i2c_controller is
       port (
            clk         : in    std_logic;
            reset_n     : in    std_logic;
            i2c_frame   : in    std_logic_vector(23 downto 0);
            i2c_sda     : inout std_logic;
            i2c_scl     : out   std_logic;
            i2c_RW      : in    std_logic;
            i2c_start   : in    std_logic;
            i2c_stop    : in    std_logic;
            i2c_ack     : out   std_logic;
            i2c_bit_cnt : out   std_logic_vector(5 downto 0);  
            i2c_sda_out : out   std_logic
       );
    end component;

    constant CLK_FREQ   : integer := 50_000_000;
    constant I2C_FREQ   : integer := 20_000;
    constant LUT_SIZE   : integer := 30;            -- (31 entries)

    type lut_array is array (0 to LUT_SIZE) of std_logic_vector(15 downto 0);
    constant LUT_DATA : lut_array := (
        0  => x"9803", 1  => x"0100", 2  => x"0218", 3  => x"0300",
        4  => x"1470", 5  => x"1520", 6  => x"1630", 7  => x"1846",
        8  => x"4080", 9  => x"4110", 10 => x"49A8", 11 => x"5510",
        12 => x"5608", 13 => x"96F6", 14 => x"7307", 15 => x"761f",
        16 => x"9803", 17 => x"9902", 18 => x"9ae0", 19 => x"9c30",
        20 => x"9d61", 21 => x"a2a4", 22 => x"a3a4", 23 => x"a504",
        24 => x"ab40", 25 => x"af16", 26 => x"ba60", 27 => x"d1ff",
        28 => x"de10", 29 => x"e460", 30 => x"fa7d",
        others => x"9803"
    );

    signal i2c_ctrl_clk : std_logic;
    signal clk_div      : unsigned(15 downto 0) := (others => '0');

    signal lut_index       : integer range 0 to LUT_SIZE := 0;
    signal setup_st        : integer range 0 to 3 := 0;
    signal i2c_go          : std_logic := '0';
    signal i2c_end         : std_logic;
    signal i2c_ack         : std_logic;
    signal i2c_data        : std_logic_vector(23 downto 0);
    signal config_done_reg : std_logic := '0';

begin

    config_done <= config_done_reg;

    -- I2C clock divider
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                clk_div      <= (others => '0');
                i2c_ctrl_clk <= '0';
            else
                if clk_div < (CLK_FREQ / I2C_FREQ / 2 - 1) then
                    clk_div <= clk_div + 1;
                else
                    clk_div      <= (others => '0');
                    i2c_ctrl_clk <= not i2c_ctrl_clk;
                end if;
            end if;
        end if;
    end process;

    -- I2C controller
    i2c_inst : entity work.i2c_controller
        port map (
            clk         => i2c_ctrl_clk,
            reset_n     => reset_n,
            i2c_frame   => i2c_data,
            i2c_sda     => i2c_sda,
            i2c_scl     => i2c_scl,
            i2c_RW      => '0',
            i2c_start   => i2c_go,
            i2c_stop    => i2c_end,
            i2c_ack     => i2c_ack,
            i2c_bit_cnt => open,
            i2c_sda_out => open
        );

    -- Configuration state machine
    process(i2c_ctrl_clk)
    begin
        if rising_edge(i2c_ctrl_clk) then
            if reset_n = '0' then
                lut_index       <= 0;
                setup_st        <= 0;
                i2c_go          <= '0';
                config_done_reg <= '0';
            else
                if lut_index <= LUT_SIZE then
                    case setup_st is
                        when 0 =>
                            i2c_data <= x"72" & LUT_DATA(lut_index);
                            i2c_go   <= '1';
                            setup_st <= 1;
                        when 1 =>
                            if i2c_end = '1' then
                                i2c_go <= '0';
                                if i2c_ack = '0' then
                                    setup_st <= 2;
                                else
                                    setup_st <= 0;  -- NACK: retry
                                end if;
                            end if;
                        when 2 =>
                            lut_index <= lut_index + 1;
                            setup_st  <= 0;
                        when others =>
                            setup_st <= 0;
                    end case;
                else
                    config_done_reg <= '1';
                    if hdmi_tx_int = '0' then
                        lut_index       <= 0;
                        config_done_reg <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;