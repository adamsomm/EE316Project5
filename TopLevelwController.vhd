library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity TopLevelwController is
  generic (
    N  : integer := 8;
    N2 : integer := 255;
    N1 : integer := 0);
  port (
    clk_125mhz : in std_logic; -- 125 MHz input clock
    reset      : in std_logic;
    Ax         : in std_logic;
    Ay         : in std_logic;
    Bx         : in std_logic;
    By         : in std_logic;
    -- VGA output signals
    vga_hsync : out std_logic;
    vga_vsync : out std_logic;
    vga_red   : out std_logic_vector(3 downto 0);
    vga_green : out std_logic_vector(3 downto 0);
    vga_blue  : out std_logic_vector(3 downto 0)
  );
end TopLevelwController;

architecture Structural of TopLevelwController is
  component btn_debounce_toggle is
    generic (
      constant CNTR_MAX : std_logic_vector(15 downto 0) := X"FFFF");
    port (
      BTN_I    : in std_logic;
      CLK      : in std_logic;
      BTN_O    : out std_logic;
      TOGGLE_O : out std_logic;
      PULSE_O  : out std_logic
    );
  end component;
  component StateMachine
    port (
      A       : in std_logic;
      B       : in std_logic;
      reset_n : in std_logic;
      clock   : in std_logic;
      up      : out std_logic;
      en      : out std_logic
    );
  end component;
  component Reset_Delay is
    port (
      iCLK   : in std_logic;
      oRESET : out std_logic
    );
  end component;
  component univ_bin_counter is
    generic (
      N  : integer := 8;
      N2 : integer := 255;
      N1 : integer := 0);
    port (
      clk, reset            : in std_logic;
      syn_clr, load, en, up : in std_logic;
      clk_en                : in std_logic := '1';
      d                     : in std_logic_vector(N - 1 downto 0);
      max_tick, min_tick    : out std_logic;
      q                     : out std_logic_vector(N - 1 downto 0)
    );
  end component;
  -- Component declaration for the ROM
  component blk_mem_gen_0
    port (
      -- Port A (Write)
      clka  : in std_logic;
      wea   : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(15 downto 0);
      dina  : in std_logic_vector(11 downto 0);
      -- Port B (Read) 
      clkb  : in std_logic;
      addrb : in std_logic_vector(15 downto 0);
      doutb : out std_logic_vector(11 downto 0)
    );
  end component;
  component vga_controller
    port (
      clk_125mhz : in std_logic;
      pix_en     : in std_logic;
      reset      : in std_logic;
      vga_hsync  : out std_logic;
      vga_vsync  : out std_logic;
      vga_red    : out std_logic_vector(3 downto 0);
      vga_green  : out std_logic_vector(3 downto 0);
      vga_blue   : out std_logic_vector(3 downto 0);
      bram_addr  : out std_logic_vector(15 downto 0);
      bram_data  : in std_logic_vector(11 downto 0)
    );
  end component;

  component ControllerStateMachine
    port (
      clk        : in std_logic;
      reset      : in std_logic;
      qx         : in std_logic_vector(7 downto 0);
      qy         : in std_logic_vector(7 downto 0);
      RAMaddress : out std_logic_vector(15 downto 0);
      RAMdata    : out std_logic_vector(11 downto 0)
    );
  end component;

  signal reset_d : std_logic := '0';

  signal Bx_db        : std_logic;
  signal Ax_db        : std_logic;
  signal upx          : std_logic;
  signal enx          : std_logic;
  signal system_reset : std_logic;
  signal qx           : std_logic_vector(N - 1 downto 0);
  signal By_db        : std_logic;
  signal Ay_db        : std_logic;
  signal upy          : std_logic;
  signal eny          : std_logic;
  signal qy           : std_logic_vector(N - 1 downto 0);
  -- Constants for clock division (125MHz -> 25MHz)
  constant CLK_DIVIDER : integer                            := 5; -- 125MHz / 5 = 25MHz
  signal clk_counter   : integer range 0 to CLK_DIVIDER - 1 := 0;
  signal pixel_en      : std_logic;
  -- RAM interface signals
  signal ram_addr_porta : std_logic_vector(15 downto 0);
  signal ram_data_porta : std_logic_vector(11 downto 0);
  signal ram_addr_portb : std_logic_vector(15 downto 0);
  signal ram_data_portb : std_logic_vector(11 downto 0);
  --   attribute mark_debug : string; 
  -- attribute mark_debug of qx     : signal is "true";
  -- attribute mark_debug of qy     : signal is "true";
  -- attribute mark_debug of eny     : signal is "true";
  -- attribute mark_debug of enx     : signal is "true";
  -- attribute mark_debug of upy     : signal is "true";
  -- attribute mark_debug of upx     : signal is "true";
begin
  system_reset <= reset_d or reset;
  -- Clock divider: 125MHz -> 25MHz (for VGA timing)
  process (clk_125mhz, reset)
  begin
    if reset = '1' then
      clk_counter <= 0;
      pixel_en    <= '0';
    elsif rising_edge(clk_125mhz) then
      if clk_counter = 4 then
        clk_counter <= 0;
        pixel_en    <= '1';
      else
        clk_counter <= clk_counter + 1;
        pixel_en    <= '0';
      end if;
    end if;
  end process;

  ControllerStateMachine_inst : ControllerStateMachine
    port map
    (
      clk        => clk_125mhz,
      reset      => system_reset,
      qx         => qx,
      qy         => qy,
      RAMaddress => ram_addr_porta,
      RAMdata    => ram_data_porta
    );

  -- Instantiate the dual-port RAM
  ram_inst : blk_mem_gen_0
  port map
  (
    -- Write Port (A)
    clka  => clk_125mhz, -- Write clock
    wea   => "1", -- Always enabled for writing
    addra => ram_addr_porta, -- From your write controller
    dina  => ram_data_porta, -- 12-bit input data

    -- Read Port (B) 
    clkb  => clk_125mhz, -- Can be same or different clock
    addrb => ram_addr_portb, -- From VGA controller
    doutb => ram_data_portb -- To VGA controller
  );
  -- VGA Controller Instance (runs at 25MHz)
  vga_controller_inst : vga_controller
  port map
  (
    clk_125mhz => clk_125mhz,
    pix_en     => pixel_en,
    reset      => reset,
    vga_hsync  => vga_hsync,
    vga_vsync  => vga_vsync,
    vga_red    => vga_red,
    vga_green  => vga_green,
    vga_blue   => vga_blue,
    bram_addr  => ram_addr_portb,
    bram_data  => ram_data_portb
  );

  univ_bin_counter_instx : univ_bin_counter
  generic map(
    N  => N,
    N2 => N2,
    N1 => N1
  )
  port map
  (
    clk      => clk_125mhz,
    reset    => system_reset,
    syn_clr  => '0',
    load     => '0',
    en       => enx,
    up       => upx,
    clk_en   => '1',
    d => (others => '0'),
    max_tick => open,
    min_tick => open,
    q        => qx
  );
  StateMachine_instx : StateMachine
  port map
  (
    A       => Ax_db,
    B       => Bx_db,
    reset_n => system_reset,
    clock   => clk_125mhz,
    up      => upx,
    en      => enx
  );
  inst_Ax : btn_debounce_toggle
  generic map(CNTR_MAX => X"000F") -- X'FFFF" for implementation       
  port map
  (
    BTN_I    => Ax,
    CLK      => clk_125mhz,
    BTN_O    => Ax_db,
    TOGGLE_O => open,
    PULSE_O  => open
  );
  inst_Bx : btn_debounce_toggle
  generic map(CNTR_MAX => X"000F") -- X'FFFF" for implementation       
  port map
  (
    BTN_I    => Bx,
    CLK      => clk_125mhz,
    BTN_O    => Bx_db,
    TOGGLE_O => open,
    PULSE_O  => open
  );
  -- y
  univ_bin_counter_insty : univ_bin_counter
  generic map(
    N  => N,
    N2 => N2,
    N1 => N1
  )
  port map
  (
    clk      => clk_125mhz,
    reset    => system_reset,
    syn_clr  => '0',
    load     => '0',
    en       => eny,
    up       => upy,
    clk_en   => '1',
    d => (others => '0'),
    max_tick => open,
    min_tick => open,
    q        => qy
  );
  StateMachine_insty : StateMachine
  port map
  (
    A       => Ay_db,
    B       => By_db,
    reset_n => system_reset,
    clock   => clk_125mhz,
    up      => upy,
    en      => eny
  );
  inst_Ay : btn_debounce_toggle
  generic map(CNTR_MAX => X"000F") -- X'FFFF" for implementation       
  port map
  (
    BTN_I    => Ay,
    CLK      => clk_125mhz,
    BTN_O    => Ay_db,
    TOGGLE_O => open,
    PULSE_O  => open
  );
  inst_By : btn_debounce_toggle
  generic map(CNTR_MAX => X"000F") -- X'FFFF" for implementation       
  port map
  (
    BTN_I    => By,
    CLK      => clk_125mhz,
    BTN_O    => By_db,
    TOGGLE_O => open,
    PULSE_O  => open
  );
  Reset_Delay_inst : Reset_Delay
  port map
  (
    iCLK   => clk_125mhz,
    oRESET => reset_d
  );
end Structural;