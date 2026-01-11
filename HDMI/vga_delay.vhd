library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vga_controller.all;

entity vga_delay is
    generic (
        NUM_PIPES  : natural     := 2;  
        COORD_BITS : natural    := 12; -- 4096 pixels
        vga_res    : vga_timing := vga_res_1920x1080
    );
    port (
        clk             : in  std_logic;
        reset_n         : in  std_logic;
        -- Delayed Outputs
        h_sync_d        : out std_logic;
        v_sync_d        : out std_logic;
        point_valid_d   : out boolean;
        pixel_coord_d   : out coordinate;
        vga_blank_n_d   : out std_logic
    );
end entity vga_delay;

architecture rtl of vga_delay is
    component hyper_pipe is
         generic (
             WIDTH      : natural := 1;
             NUM_PIPES : natural  := 1
         );
         port (
             clk  : in  std_logic;
             din  : in  std_logic_vector(WIDTH-1 downto 0);
             dout : out std_logic_vector(WIDTH-1 downto 0)
         );
    end component hyper_pipe;
    
    component vga_fsm is
         generic (
             vga_res: vga_timing := vga_res_1920x1080
         );
         port (
             vga_clk       : in std_logic;   
             reset_n       : in std_logic;
             h_sync        : out std_logic;
             v_sync        : out std_logic;
             point_valid   : out boolean; 
             pixel_coord   : out coordinate;
             vga_blank_n   : out std_logic
         );
    end component vga_fsm;
    
    signal h_sync        : std_logic;
    signal v_sync        : std_logic;
    signal blank_n       : std_logic;
    signal pt_valid      : boolean;
    signal pt_coord      : coordinate;
    signal pt_valid_sl   : std_logic;

    -- Calculate total width for the pipeline
    -- 1 bit each for: h_sync, v_sync, blank, valid
    -- COORD_BITS each for: x, y
    constant PIPE_WIDTH     : natural := 4 + (2 * COORD_BITS);
    
    signal pipe_in          : std_logic_vector(PIPE_WIDTH-1 downto 0);
    signal pipe_out         : std_logic_vector(PIPE_WIDTH-1 downto 0);

begin

    -- 1. Instantiate the Source FSM
    vga_controller : component vga_fsm
        generic map (
            vga_res => vga_res
          )
        port map (
            vga_clk     => clk,
            reset_n     => reset_n,
            h_sync      => h_sync,
            v_sync      => v_sync,
            point_valid => pt_valid,
            pixel_coord => pt_coord,
            vga_blank_n => blank_n
      );

    -- Pack Data: Cast types to std_logic_vector and concatenate
    pt_valid_sl <= '1' when pt_valid else '0';
    pipe_in <= h_sync & v_sync & blank_n & pt_valid_sl & std_logic_vector(to_unsigned(pt_coord.x, COORD_BITS)) & std_logic_vector(to_unsigned(pt_coord.y, COORD_BITS));

    -- 3. Pipeline Delay
    delay : component hyper_pipe
        generic map (
            WIDTH     =>  PIPE_WIDTH, 
            NUM_PIPES => NUM_PIPES
            )
        port map (
            clk  => clk, 
            din  => pipe_in, 
            dout => pipe_out
        );

    -- 4. Unpack Data: Slice vector and cast back to original types
    h_sync_d      <= pipe_out(PIPE_WIDTH-1);
    v_sync_d      <= pipe_out(PIPE_WIDTH-2);
    vga_blank_n_d <= pipe_out(PIPE_WIDTH-3);
    
    point_valid_d <= true when pipe_out(PIPE_WIDTH-4) = '1' else false;

    pixel_coord_d.x <= to_integer(unsigned(pipe_out(2*COORD_BITS-1 downto COORD_BITS)));
    pixel_coord_d.y <= to_integer(unsigned(pipe_out(COORD_BITS-1 downto 0)));

end architecture rtl;