---------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_user_logic is   -- tx_out
  Port ( 
       tx_data                 : in std_logic_vector(7 DOWNTO 0);
       tx_pulse                : in std_logic;
       iclk                    : in std_logic;   
	   tx                      : out std_logic; -- tx_out will be assigned to tx pin of the controller
       rx                      : in std_logic;
       reset                   : in std_logic;
       regPulse                : out std_logic;
       
	   LCD_Data                : out std_logic_vector(127 DOWNTO 0) := X"30303030303030303030303030303030";
	   Mode					   : out std_logic_vector(2 DOWNTO 0) := "000";
	   Seven_seg			   : out std_logic_vector(15 downto 0)
		 );
end uart_user_logic;

architecture Behavioral of uart_user_logic is
component uart is
    port (
        reset       :in  std_logic;
        txclk       :in  std_logic;
        ld_tx_data  :in  std_logic;
        tx_data     :in  std_logic_vector (7 downto 0);
        tx_enable   :in  std_logic;
        tx_out      :out std_logic;
        tx_empty    :out std_logic;
        rxclk       :in  std_logic;
        uld_rx_data :in  std_logic;
        rx_data     :out std_logic_vector (7 downto 0);
        rx_enable   :in  std_logic;
        rx_in       :in  std_logic;
        rx_empty    :out std_logic
    );
end component;

component Shift_Reg is
	GENERIC (
        sr_depth : integer := 136;  -- Depth of the shift register
        input_width : integer := 8  -- Width of the input data
    );    
	port(	
		clock:		in std_logic;
		reset :		in std_logic;
		en: 			in std_logic;
		sr_in:		in std_logic_vector(7 downto 0);
		sr_out:		out std_logic_vector(sr_depth-1 downto 0) :=(others => '0')
	);
end component;

component debounce IS
  GENERIC(
    counter_size  :  INTEGER := 20); --counter size (19 bits gives 10.5ms with 50MHz clock)
  PORT(
    clk     : IN  STD_LOGIC;  --input clock
    button  : IN  STD_LOGIC;  --input signal to be debounced
    result  : OUT STD_LOGIC); --debounced signal
end component;


component btn_debounce_toggle is
GENERIC (
	CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"0001");  --fde8
    Port ( BTN_I 	: in  STD_LOGIC;
           CLK 		: in  STD_LOGIC;
           BTN_O 	: out  STD_LOGIC;
           TOGGLE_O : out  STD_LOGIC;
		   PULSE_O  : out STD_LOGIC);
end component;

TYPE state_type IS (IDLE,TRANSMISSION, RECEIVER);
signal state : state_type;

-- UART SIGNALS
--signal reset : std_logic := '0';
signal txclk : std_logic;
signal ld_tx_data : std_logic;
signal tx_enable : std_logic;
signal tx_out : std_logic;
signal tx_empty : std_logic;
signal rxclk : std_logic;
signal uld_rx_data : std_logic;
signal rx_data    : std_logic_vector(7 DOWNTO 0);
signal rx_enable : std_logic;
--signal rx_in    : std_logic;
signal rx_empty : std_logic;
signal rx_full : std_logic;



--signal Mode					   :  std_logic_vector(2 DOWNTO 0);
--signal Seven_seg			   :  std_logic_vector(0 DOWNTO 0);
--signal LCD_data                : std_logic_vector(127 downto 0);

-- SHIFT REGISTER SIGNALS --
signal sr_out	: std_logic_vector(135 downto 0);
--signal sr_in0	  : std_logic_vector(7 DOWNTO 0);
--signal sr_in1	  :std_logic_vector(7 DOWNTO 0);
--signal sr_in2    : std_logic_vector(7 DOWNTO 0);
--signal sr_in3    : std_logic_vector(7 DOWNTO 0);
--signal sr_in4    : std_logic_vector(7 DOWNTO 0);
--signal sr_in5    : std_logic_vector(7 DOWNTO 0);
--signal sr_in6    : std_logic_vector(7 DOWNTO 0);
--signal sr_in7    : std_logic_vector(7 DOWNTO 0);
--signal sr_in8    : std_logic_vector(7 DOWNTO 0);
--signal sr_in9    : std_logic_vector(7 DOWNTO 0);
--signal sr_in10   : std_logic_vector(7 DOWNTO 0);
--signal sr_in11   : std_logic_vector(7 DOWNTO 0);
--signal sr_in12   : std_logic_vector(7 DOWNTO 0);
--signal sr_in13   : std_logic_vector(7 DOWNTO 0);
--signal sr_in14   : std_logic_vector(7 DOWNTO 0);
--signal sr_in15   : std_logic_vector(7 DOWNTO 0);
--signal sr_in16   : std_logic_vector(7 DOWNTO 0);

signal shiftcount       : integer range 0 to 17;
signal rx_empty_db      : std_logic;
signal shift_trig       : std_logic;
signal old_shift_trig   : std_logic;
signal uartconcat       : std_logic_vector(7 downto 0);

-- Clock divider signals
signal tx_clk_div   : std_logic := '0';
signal div_cnttx   : integer := 0;
constant DIV_MAXtx : integer := 6510;  -- Adjust this constant if needed
signal rx_clk_div   : std_logic := '0';
signal div_cntrx   : integer := 0;
constant DIV_MAXrx : integer := 400;  -- Adjust this constant if needed 16x is 814
signal firstpulse: std_logic;

-- attribute mark_debug : string; 
-- attribute mark_debug of rx_data     : signal is "true";
-- attribute mark_debug of rx_full  : signal is "true";
-- attribute mark_debug of shift_trig     : signal is "true";
-- attribute mark_debug of shiftcount  : signal is "true";
-- attribute mark_debug of tx_data  : signal is "true";

-- attribute mark_debug of sr_out : signal is "true";



begin

-- CLOCK ENABLER FOR TXCLK and RXCLK --

--Inst_clk_en :process(iCLK)
--	begin
--	if rising_edge(iCLK) then
--		if (clk_cnt = 13020) then --49999999
--			clk_cnt <= 0;
--			clk_en <= '1';
--		else
--			clk_cnt <= clk_cnt + 1;
--			clk_en <= '0';
--		end if;
--	end if;
--	end process;
-- Clock divider signals

-- Clock divider process
process(iclk)
begin
    if rising_edge(iclk) then
        if div_cnttx = DIV_MAXtx then
            div_cnttx <= 0;
            tx_clk_div <= not tx_clk_div;  -- Toggle divided clock
        else
            div_cnttx <= div_cnttx + 1;
        end if;
    end if;
end process;

process(iclk)
begin
    if rising_edge(iclk) then
        if div_cntrx = DIV_MAXrx then
            div_cntrx <= 0;
            rx_clk_div <= not rx_clk_div;  -- Toggle divided clock
        else
            div_cntrx <= div_cntrx + 1;
        end if;
    end if;
end process;

--process(iclk)
--    variable count : integer range 0 to 13020 := 0;  -- Counter for 13,021 clock cycles
--begin
--    if rising_edge(iclk) then
--        -- Start the baud rate cycle on tx_pulse or if already in progress
--        if (tx_pulse = '1' or firstpulse = '1') then
--            firstpulse <= '1';  -- Indicate that the baud rate cycle is in progress
--            if count = 13020 then  -- End of baud rate cycle
--                baudPulse <= '0';  -- Set baudPulse low
--                firstpulse <= '0'; -- Reset the cycle
--                count := 0;        -- Reset the counter
--            else
--                baudPulse <= '1';  -- Keep baudPulse high during the cycle
--                count := count + 1; -- Increment the counter
--            end if;
--        end if;
--    end if;
--end process;
rx_full <= not rx_empty;
regPulse <= rx_empty;
process(iclk)
begin
    if reset = '1' then
        old_shift_trig <= '0';
        
        shiftcount <= 0;
        LCD_Data <= (others => '0');
        Seven_seg <= X"0006";
        Mode <= "000";
	elsif rising_edge(iclk) then
	old_shift_trig <= shift_trig;
	if shift_trig = '0' and old_shift_trig = '1' then
		shiftcount <= shiftcount + 1;
	end if;
	if shiftcount > 16 then
			LCD_Data <= sr_out(135 downto 8);
			Mode <= sr_out(6 downto 4);
			Seven_seg <= X"000" & sr_out(3 downto 0);
			shiftcount <= 0;
		end if;
	end if;
end process;

uart_master_inst : uart
    port map(
        reset       => reset,
        txclk       => tx_clk_div,
        ld_tx_data  => '1',
        tx_data     => tx_data,
        tx_enable   => tx_pulse,
        tx_out      => tx,
        tx_empty    => tx_empty,
        rxclk       => rx_clk_div,
        uld_rx_data => '1',
        rx_data     => rx_data,
        rx_enable   => '1',
        rx_in       => rx,
        rx_empty    => rx_empty
    );

debouncer_inst : btn_debounce_toggle
	PORT MAP(
    BTN_I => rx_full,
    CLK => iclk,
    BTN_O => open, 
    TOGGLE_O => open,
    PULSE_O => shift_trig
    );
	 
shift_register_inst0 : Shift_Reg 
GENERIC map(
        sr_depth => 136,  -- Depth of the shift register
        input_width => 8  -- Width of the input data
    ) 
	  PORT MAP(
	   clock => iclk,
		reset => reset,
		en => shift_trig, 			
		sr_in => rx_data,
		sr_out => sr_out
		);	
	
end Behavioral;
