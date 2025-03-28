library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity vga_top_EncoderAdd_tb is
end vga_top_EncoderAdd_tb;

architecture Behavioral of vga_top_EncoderAdd_tb is
    -- Component Declaration for the Unit Under Test (UUT)
    component vga_top_EncoderAdd
        generic(
            N  : integer := 8;
            N2 : integer := 255;
            N1 : integer := 0
        );
        port(
            clk_125mhz : in  std_logic;
            reset      : in  std_logic;
            Ax         : in  std_logic;
            Ay         : in  std_logic;
            Bx         : in  std_logic;
            By         : in  std_logic;
            vga_hsync  : out std_logic;
            vga_vsync  : out std_logic;
            vga_red    : out std_logic_vector(3 downto 0);
            vga_green  : out std_logic_vector(3 downto 0);
            vga_blue   : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Inputs
    signal clk_125mhz : std_logic := '0';
    signal reset      : std_logic := '0';
    signal Ax         : std_logic := '0';
    signal Ay         : std_logic := '0';
    signal Bx         : std_logic := '0';
    signal By         : std_logic := '0';

    -- Outputs
    signal vga_hsync : std_logic;
    signal vga_vsync : std_logic;
    signal vga_red   : std_logic_vector(3 downto 0);
    signal vga_green : std_logic_vector(3 downto 0);
    signal vga_blue  : std_logic_vector(3 downto 0);

    -- Clock period definitions
    constant clk_period : time := 8 ns; -- 125 MHz

    -- Testbench signals
    type encoder_sequence is array (natural range <>) of std_logic_vector(1 downto 0);
    
    -- Encoder sequence for adding (clockwise rotation)
    constant add_sequence : encoder_sequence := 
        ("11", "01", "00", "10", "11");
    
    -- Encoder sequence for subtracting (counter-clockwise rotation)
    constant sub_sequence : encoder_sequence := 
        ("11", "10", "00", "01", "11");

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: vga_top_EncoderAdd 
        generic map(
            N  => 8,
            N2 => 255,
            N1 => 0
        )
        port map(
            clk_125mhz => clk_125mhz,
            reset      => reset,
            Ax         => Ax,
            Ay         => Ay,
            Bx         => Bx,
            By         => By,
            vga_hsync  => vga_hsync,
            vga_vsync  => vga_vsync,
            vga_red    => vga_red,
            vga_green  => vga_green,
            vga_blue   => vga_blue
        );

    -- Clock process definitions
    clk_process : process
    begin
        clk_125mhz <= '0';
        wait for clk_period/2;
        clk_125mhz <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
        procedure apply_encoder_sequence(
            signal A, B : out std_logic;
            sequence : encoder_sequence;
            step_delay : time
        ) is
        begin
            for i in sequence'range loop
                A <= sequence(i)(1);
                B <= sequence(i)(0);
                wait for step_delay;
            end loop;
        end procedure;
    begin
        -- Initial reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- Test X encoder - add 5 counts
        for i in 1 to 5 loop
            report "Applying X encoder add sequence #" & integer'image(i);
            apply_encoder_sequence(Ax, Bx, add_sequence, 1 us);
            wait for 5 us;
        end loop;

        wait for 10 us;

        -- Test X encoder - subtract 3 counts
        for i in 1 to 3 loop
            report "Applying X encoder subtract sequence #" & integer'image(i);
            apply_encoder_sequence(Ax, Bx, sub_sequence, 1 us);
            wait for 5 us;
        end loop;

        wait for 10 us;

        -- Test Y encoder - add 4 counts
        for i in 1 to 4 loop
            report "Applying Y encoder add sequence #" & integer'image(i);
            apply_encoder_sequence(Ay, By, add_sequence, 1 us);
            wait for 5 us;
        end loop;

        wait for 10 us;

        -- Test Y encoder - subtract 2 counts
        for i in 1 to 2 loop
            report "Applying Y encoder subtract sequence #" & integer'image(i);
            apply_encoder_sequence(Ay, By, sub_sequence, 1 us);
            wait for 5 us;
        end loop;

        wait for 10 us;

        -- Test both encoders simultaneously
        for i in 1 to 3 loop
            report "Applying both encoders simultaneously - add sequence #" & integer'image(i);
            apply_encoder_sequence(Ax, Bx, add_sequence, 1 us);
            apply_encoder_sequence(Ay, By, sub_sequence, 1.2 us);
            wait for 5 us;
        end loop;

        -- End simulation
        report "Simulation completed";
        wait;
    end process;

end Behavioral;