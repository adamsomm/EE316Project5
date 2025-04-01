library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
    port (
        clk_125mhz : in  std_logic;
        pix_en     : in  std_logic;
        reset      : in  std_logic;
        res        : in integer;
        vga_hsync  : out std_logic;
        vga_vsync  : out std_logic;
        vga_red    : out std_logic_vector(3 downto 0);
        vga_green  : out std_logic_vector(3 downto 0);
        vga_blue   : out std_logic_vector(3 downto 0);
        bram_addr  : out std_logic_vector(16 downto 0);
        bram_data  : in  std_logic_vector(11 downto 0)
    );
end vga_controller;

architecture Behavioral of vga_controller is
    -- VESA timings for 640x480@60Hz (25MHz pixel clock)
    constant H_DISPLAY : integer := 640;
    constant H_FP      : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BP      : integer := 48;
    constant H_TOTAL   : integer := H_DISPLAY + H_FP + H_SYNC + H_BP;
    
    constant V_DISPLAY : integer := 480;
    constant V_FP      : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BP      : integer := 33;
    constant V_TOTAL   : integer := V_DISPLAY + V_FP + V_SYNC + V_BP;
    
    -- Image positioning
    signal IMG_WIDTH  : integer := 256;-- change this dynamically
    signal IMG_HEIGHT : integer := 256;-- change this 
    signal H_START    : integer := (H_DISPLAY - IMG_WIDTH)/2;--make a signal
    signal V_START    : integer := (V_DISPLAY - IMG_HEIGHT)/2;-- make a signal
    
    -- Internal signals
    signal h_counter    : integer range 0 to H_TOTAL-1 := 0;
    signal v_counter    : integer range 0 to V_TOTAL-1 := 0;
    signal rgb          : std_logic_vector(11 downto 0);
    signal hsync_reg    : std_logic;
    signal vsync_reg    : std_logic;
    signal blank        : std_logic;
    
begin
    IMG_WIDTH <= res;
    IMG_HEIGHT <= res;
    H_START    <= (H_DISPLAY - IMG_WIDTH)/2;--make a signal
    V_START    <= (V_DISPLAY - IMG_HEIGHT)/2;-- make a signal
    -- VGA timing generation process
    process(clk_125mhz, reset)
        variable bram_x, bram_y : integer;
    begin
        if reset = '1' then
            h_counter <= 0;
            v_counter <= 0;
            hsync_reg <= '1';
            vsync_reg <= '1';
            blank <= '1';
            rgb <= (others => '0');
            bram_addr <= (others => '0');
        elsif rising_edge(clk_125mhz) then
            if pix_en = '1' then
                -- Horizontal counter logic
                if h_counter = H_TOTAL-1 then
                    h_counter <= 0;
                    -- Vertical counter logic
                    if v_counter = V_TOTAL-1 then
                        v_counter <= 0;
                    else
                        v_counter <= v_counter + 1;
                    end if;
                else
                    h_counter <= h_counter + 1;
                end if;

                -- HSYNC generation (VHDL-2002 compatible)
                if (h_counter >= H_DISPLAY + H_FP) and 
                   (h_counter < H_DISPLAY + H_FP + H_SYNC) then
                    hsync_reg <= '0';
                else
                    hsync_reg <= '1';
                end if;

                -- VSYNC generation (VHDL-2002 compatible)
                if (v_counter >= V_DISPLAY + V_FP) and 
                   (v_counter < V_DISPLAY + V_FP + V_SYNC) then
                    vsync_reg <= '0';
                else
                    vsync_reg <= '1';
                end if;

                -- Blanking signal generation
                if (h_counter < H_DISPLAY) and (v_counter < V_DISPLAY) then
                    blank <= '0';
                else
                    blank <= '1';
                end if;

                -- Image addressing logic
                if (h_counter >= H_START) and (h_counter < H_START + IMG_WIDTH) and
                   (v_counter >= V_START) and (v_counter < V_START + IMG_HEIGHT) then
                    bram_x := h_counter - H_START;
                    bram_y := v_counter - V_START;
                    bram_addr <= std_logic_vector(to_unsigned(bram_y * IMG_WIDTH + bram_x, 17));
                    rgb <= bram_data;
                else
                    bram_addr <= (others => '0');
                    rgb <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    -- Output assignments
    vga_hsync <= hsync_reg;
    vga_vsync <= vsync_reg;
    vga_red   <= rgb(11 downto 8) when blank = '0' else "0000";
    vga_green <= rgb(7 downto 4)  when blank = '0' else "0000";
    vga_blue  <= rgb(3 downto 0)  when blank = '0' else "0000";
end Behavioral;