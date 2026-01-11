library ieee;
use ieee.std_logic_1164.all;

use work.vga_controller.all;

entity vga_fsm is
    generic (
        vga_res: vga_timing := vga_res_1920x1080
    );
    port (
        vga_clk      : in std_logic;   
        reset_n      : in std_logic;
        h_sync       : out std_logic;
        v_sync       : out std_logic;
        point_valid  : out boolean; 
        pixel_coord  : out coordinate;
        vga_blank_n  : out std_logic
    );
end entity vga_fsm;

architecture rtl of vga_fsm is
	signal current_point : coordinate;
begin
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if reset_n = '0' then
                current_point <= make_coordinate(0, 0);
            else
                current_point <= next_coordinate(current_point, vga_res);
            end if;
        end if;
    end process;
	 
    h_sync      <= horizontal_sync(current_point, vga_res);
    v_sync      <= vertical_sync(current_point, vga_res);
    point_valid <= point_visible(current_point, vga_res);
    pixel_coord <= current_point;
    vga_blank_n <= '1' when point_visible(current_point, vga_res) else '0';
end architecture rtl;