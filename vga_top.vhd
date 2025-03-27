library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_top is
    port (
        clk_125mhz : in  std_logic;  -- 125 MHz input clock
        reset      : in  std_logic;
        -- VGA output signals
        vga_hsync  : out std_logic;
        vga_vsync  : out std_logic;
        vga_red    : out std_logic_vector(3 downto 0);
        vga_green  : out std_logic_vector(3 downto 0);
        vga_blue   : out std_logic_vector(3 downto 0)
    );
end vga_top;

architecture Structural of vga_top is
    -- Component declaration for the ROM
    component blk_mem_gen_0
        port (
            clka  : in  std_logic;
            addra : in  std_logic_vector(15 downto 0);
            douta : out std_logic_vector(11 downto 0)
        );
    end component;

    -- Constants for clock division (125MHz -> 25MHz)
    constant CLK_DIVIDER : integer := 5;  -- 125MHz / 5 = 25MHz
    signal clk_counter   : integer range 0 to CLK_DIVIDER-1 := 0;
    signal pixel_clk     : std_logic;
    
    -- RAM interface signals
    signal rom_addr      : std_logic_vector(15 downto 0);
    signal rom_data      : std_logic_vector(11 downto 0);
    
begin
    -- Clock divider: 125MHz -> 25MHz (for VGA timing)
    process(clk_125mhz, reset)
    begin
        if reset = '1' then
            clk_counter <= 0;
            pixel_clk <= '0';
        elsif rising_edge(clk_125mhz) then
            if clk_counter = CLK_DIVIDER-1 then
                clk_counter <= 0;
                pixel_clk <= not pixel_clk;
            else
                clk_counter <= clk_counter + 1;
            end if;
        end if;
    end process;

    -- VGA Controller Instance (runs at 25MHz)
    vga_controller_inst: entity work.vga_controller
        port map (
            clk_50mhz => pixel_clk,  -- Actually 25MHz (legacy port name)
            reset     => reset,
            vga_hsync => vga_hsync,
            vga_vsync => vga_vsync,
            vga_red   => vga_red,
            vga_green => vga_green,
            vga_blue  => vga_blue,
            bram_addr => rom_addr,
            bram_data => rom_data
        );

    -- Block Memory Generator Instance
    -- Note: Using 125MHz clock for synchronous reads with VGA controller
    rom_inst: blk_mem_gen_0
        port map (
            clka  => clk_125mhz,  -- Full speed clock
            addra => rom_addr,
            douta => rom_data
        );
        
end Structural;