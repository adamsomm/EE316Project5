library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_top is
    port (
        clk_125mhz : in  std_logic;
        reset      : in  std_logic;
        vga_hsync  : out std_logic;
        vga_vsync  : out std_logic;
        vga_red    : out std_logic_vector(3 downto 0);
        vga_green  : out std_logic_vector(3 downto 0);
        vga_blue   : out std_logic_vector(3 downto 0)
    );
end vga_top;

architecture Structural of vga_top is
    component blk_mem_gen_0
        port (
            clka  : in  std_logic;
            addra : in  std_logic_vector(15 downto 0);
            douta : out std_logic_vector(11 downto 0)
        );
    end component;

    -- Clock enable signals
    signal pixel_en      : std_logic;
    signal clk_counter   : integer range 0 to 4 := 0;
    
    -- RAM interface
    signal rom_addr      : std_logic_vector(15 downto 0);
    signal rom_data      : std_logic_vector(11 downto 0);
    
begin
    -- Clock enable generator (25MHz enable from 125MHz)
    process(clk_125mhz, reset)
    begin
        if reset = '1' then
            clk_counter <= 0;
            pixel_en <= '0';
        elsif rising_edge(clk_125mhz) then
            if clk_counter = 4 then
                clk_counter <= 0;
                pixel_en <= '1';
            else
                clk_counter <= clk_counter + 1;
                pixel_en <= '0';
            end if;
        end if;
    end process;

    -- VGA Controller
    vga_inst: entity work.vga_controller
        port map (
            clk_125mhz => clk_125mhz,
            pix_en     => pixel_en,
            reset      => reset,
            vga_hsync  => vga_hsync,
            vga_vsync  => vga_vsync,
            vga_red    => vga_red,
            vga_green  => vga_green,
            vga_blue   => vga_blue,
            bram_addr  => rom_addr,
            bram_data  => rom_data
        );

    -- Block Memory Generator
    bram_inst: blk_mem_gen_0
        port map (
            clka  => clk_125mhz,
            addra => rom_addr,
            douta => rom_data
        );
end Structural;