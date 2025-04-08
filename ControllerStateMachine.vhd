library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity ControllerStateMachine is
  port (
    clk           : in std_logic;
    reset         : in std_logic;
    qx            : in std_logic_vector(8 downto 0);
    qy            : in std_logic_vector(8 downto 0);
    kp_pulse      : in std_logic;
    keyPress      : in std_logic_vector(7 downto 0);
    color_o       : out std_logic_vector(11 downto 0) := X"000";
    SETResolution : out integer                       := 256;
    RAMaddress    : out std_logic_vector(16 downto 0);
    RAMdata       : out std_logic_vector(11 downto 0);
    LCD_data      : out std_logic_vector(255 downto 0)
  );
end ControllerStateMachine;

architecture Behavioral of ControllerStateMachine is
  -- Define state type
  type state_type is (Ready, Draw, Command, Write, Refresh);
  signal current_state : state_type := Refresh;
  type Cursor_Size is (One, Two, Three);
  signal Current_Size          : Cursor_Size := One;
  signal Current_Size_Buffered : Cursor_Size := One;
  type Screen_Size is (Standard, Twice);
  signal Screen_Resolution   : Screen_Size := Standard;
  signal Resolution_Buffered : Screen_Size := Standard;
  type keyboard is (brushColor, brushWidth, screenSize);
  signal CommandPress : keyboard := brushColor;

  signal Resolution          : integer                        := 256;
  constant DefaultColor      : std_logic_vector(11 downto 0)  := X"FFF"; -- Default color for the display
  signal resetCount          : integer                        := 0;
  signal color               : std_logic_vector(11 downto 0)  := X"000";
  signal cursorCounter       : integer                        := 0;
  signal readycount          : integer                        := 0;
  signal LCD_data_TOP        : std_logic_vector(127 downto 0) := (others => '0');
  signal LCD_data_BOT        : std_logic_vector(127 downto 0) := X"433A30303020573A3120533A31202020"; -- "C:000 W:1 S:1" in hex\
  signal Resdisplay          : std_logic_vector(7 downto 0)   := X"31"; -- "1" in hex
  signal Brushdisplay        : std_logic_vector(7 downto 0)   := X"31"; -- "1" in hex
  signal Brushdisplay_Buffer : std_logic_vector(7 downto 0);
  signal Resdisplay_Buffer   : std_logic_vector(7 downto 0);
  signal colorVector         : std_logic_vector(23 downto 0) := X"303030";
  signal colorVector_Buffer  : std_logic_vector(23 downto 0) := X"303030";

  type ColorInputStates is (IDLE, RED_INPUT, GREEN_INPUT, BLUE_INPUT);
  signal colorInputState : ColorInputStates := IDLE;

  -- 12-bit color register (4 bits red, 4 bits green, 4 bits blue)
  signal newColor : std_logic_vector(11 downto 0) := (others => '0');

  -- Previous colors for palette
  type ColorPalette is array (0 to 7) of std_logic_vector(11 downto 0);
  signal palette : ColorPalette := (
  X"FFF", X"F00", X"0F0", X"00F", -- White, Red, Green, Blue
  X"FF0", X"F0F", X"0FF", X"000" -- Yellow, Magenta, Cyan, Black
  );

  function ascii_to_4bit(ascii : in std_logic_vector(7 downto 0))
    return std_logic_vector is
    variable result : std_logic_vector(3 downto 0);
  begin
    case ascii is
      when x"30"  => result  := "0000"; -- '0'
      when x"31"  => result  := "0001"; -- '1'
      when x"32"  => result  := "0010"; -- '2'
      when x"33"  => result  := "0011"; -- '3'
      when x"34"  => result  := "0100"; -- '4'
      when x"35"  => result  := "0101"; -- '5'
      when x"36"  => result  := "0110"; -- '6'
      when x"37"  => result  := "0111"; -- '7'
      when x"38"  => result  := "1000"; -- '8'
      when x"39"  => result  := "1001"; -- '9'
      when x"61"  => result  := "1010"; -- 'a'
      when x"62"  => result  := "1011"; -- 'b'
      when x"63"  => result  := "1100"; -- 'c'
      when x"64"  => result  := "1101"; -- 'd'
      when x"65"  => result  := "1110"; -- 'e'
      when x"66"  => result  := "1111"; -- 'f'
      when others => result := "0000"; -- Default for invalid input
    end case;
    return result;
  end function;

begin
  SETResolution <= Resolution;
  -- Next state logic process
  process (current_state, qx, qy, clk, reset, kp_pulse, colorVector_Buffer)
    variable temp_addr  : unsigned(16 downto 0);
    variable x_unsigned : unsigned(8 downto 0);
    variable y_unsigned : unsigned(8 downto 0);
    constant MAX_Y      : unsigned(8 downto 0) := to_unsigned(Resolution - 1, 9);
    constant MAX_X      : unsigned(8 downto 0) := to_unsigned(Resolution - 1, 9);
    variable x_offset   : integer              := 0;
    variable y_offset   : integer              := 0;

    attribute mark_debug : string;
    --   attribute mark_debug of state_type     : signal is "true";
    --   attribute mark_debug of Current_Size     : signal is "true";
  begin
    LCD_data     <= LCD_data_BOT & LCD_data_TOP; -- Concatenate the top and bottom LCD data
    LCD_data_BOT <= X"433A" & colorVector & X"20573A" & Resdisplay & X"20533A" & Brushdisplay & X"202020"; -- "C:000 W:1 S:1" in hex
    color_o      <= color;
    if reset = '1' then
      -- add logic for resetting the display
      color              <= X"000";
      Resolution         <= 256;
      Current_Size       <= One;
      Resdisplay         <= X"31";
      Brushdisplay       <= X"31";
      current_state      <= Refresh;
      colorVector_Buffer <= X"303030";
      colorVector        <= X"303030";
    elsif rising_edge(clk) then

      case current_state is

        when Refresh =>
          -- print "Refreshing" on LCD
          -- LCDoutput <= "Refreshing"; -- convert to std_logic_vector in hex
          if resetCount < 360 ** 2 then
            RAMaddress <= std_logic_vector(to_unsigned(resetCount, RAMaddress'length));
            RAMdata    <= DefaultColor;
            resetCount <= resetCount + 1;
          else
            current_state <= Ready;
            resetCount    <= 0; -- Reset the counter after filling the display
          end if;

        when Ready =>
          -- print "Hardware Ready" on LCD
          -- LCDoutput <= "Hardware Ready"; -- convert to std_logic_vector in hex
          LCD_data_TOP <= X"48617264776172652052656164792020";
          LCD_data_BOT <= X"20202020202020202020202020202020"; -- clear bottom line
          if readycount < 375000000 then
            readycount <= readycount + 1;
          else
            current_state <= Draw; -- Transition to Draw state after the delay
            readycount    <= 0;
          end if;
          --current_state <= Draw;

        when Draw =>
          -- print "Drawing" on LCD
          LCD_data_TOP <= X"44726177696E67202020202020202020";
          --LCD_data_BOT <= X"20202020202020202020202020202020"; -- clear bottom line
          -- LCDoutput <= "Drawing"; -- convert to std_logic_vector in hex

          if kp_pulse = '1' then
            case keyPress is
              when X"63" => -- Color command c
                CommandPress  <= brushColor; -- Change the command type to brushColor for next key press 
                LCD_data_TOP  <= X"436F6D6D616E643A2043202020202020"; -- C
                current_state <= Command; -- Transition to Command state on key press pulse
              when X"77" => -- Screen Size Command s
                CommandPress  <= screenSize; -- Change the command type to screenSize for next key press
                LCD_data_TOP  <= X"436F6D6D616E643A2057202020202020"; -- S
                current_state <= Command; -- Transition to Command state on key press pulse
              when X"73" => -- brush size Command w
                CommandPress  <= brushWidth; -- Change the command type to brushWidth for next key press
                LCD_data_TOP  <= X"436F6D6D616E643A2053202020202020"; -- W
                current_state <= Command; -- Transition to Command state on key press pulse
              when X"09" =>
                current_state <= Write;
              when others =>
                --ignore other keypresses
                current_state <= Draw; -- Stay in Draw state if the key is not recognized
            end case;
          end if;

          case Screen_Resolution is
            when Standard =>
              Resolution <= 256; -- Standard resolution (now a signal)
              --              current_state <= Refresh;
            when Twice =>
              Resolution <= 360; -- Standard resolution (now a signal)
              --              current_state <= Refresh;
          end case;

          case Current_Size is --  prints different sized cursors 
            when One =>
              -- print "Cursor Size 1" on LCD
              -- LCDoutput <= "Cursor Size 1"; -- convert to std_logic_vector in hex
              x_unsigned := unsigned(qx);
              y_unsigned := MAX_Y - unsigned(qy);
              --              temp_addr := (y_unsigned * to_unsigned(Resolution, 9)) + x_unsigned;
              temp_addr := resize(y_unsigned * to_unsigned(Resolution, 9), 17) + x_unsigned; -- Drops MSB if needed
              -- Output assignments
              RAMaddress <= std_logic_vector(temp_addr);
              RAMdata    <= color;
            when Two =>
              if cursorCounter < 4 then
                -- Calculate offsets based on counter
                case cursorCounter is
                  when 0 => x_offset      := 0;
                    y_offset                := 0;
                  when 1 => x_offset      := 1;
                    y_offset                := 0;
                  when 2 => x_offset      := 0;
                    y_offset                := 1;
                  when 3 => x_offset      := 1;
                    y_offset                := 1;
                  when others => x_offset := 0;
                    y_offset                := 0;
                end case;

                -- Calculate position with boundary checking
                if unsigned(qx) + x_offset <= MAX_X and
                  unsigned(qy) + y_offset    <= MAX_Y then
                  x_unsigned := unsigned(qx) + x_offset;
                  y_unsigned := MAX_Y - (unsigned(qy) + y_offset);
                  --                  temp_addr  := y_unsigned & x_unsigned;
                  temp_addr := resize(y_unsigned * to_unsigned(Resolution, 9), 17) + x_unsigned;
                  RAMaddress <= std_logic_vector(temp_addr);
                  RAMdata    <= color;
                end if;

                cursorCounter <= cursorCounter + 1;
              else
                cursorCounter <= 0;
              end if;

            when Three =>
              if cursorCounter < 9 then
                -- Calculate offsets based on counter
                case cursorCounter is
                  when 0 => x_offset      := 0;
                    y_offset                := 0;
                  when 1 => x_offset      := 1;
                    y_offset                := 0;
                  when 2 => x_offset      := 0;
                    y_offset                := 1;
                  when 3 => x_offset      := 1;
                    y_offset                := 1;
                  when 4 => x_offset      := 0;
                    y_offset                := 2;
                  when 5 => x_offset      := 1;
                    y_offset                := 2;
                  when 6 => x_offset      := 2;
                    y_offset                := 0;
                  when 7 => x_offset      := 2;
                    y_offset                := 1;
                  when 8 => x_offset      := 2;
                    y_offset                := 2;
                  when others => x_offset := 0;
                    y_offset                := 0;
                end case;

                -- Calculate position with boundary checking
                if unsigned(qx) + x_offset <= MAX_X and
                  unsigned(qy) + y_offset    <= MAX_Y then
                  x_unsigned := unsigned(qx) + x_offset;
                  y_unsigned := MAX_Y - (unsigned(qy) + y_offset);
                  --                  temp_addr  := y_unsigned & x_unsigned;
                  temp_addr := resize(y_unsigned * to_unsigned(Resolution, 9), 17) + x_unsigned;
                  RAMaddress <= std_logic_vector(temp_addr);
                  RAMdata    <= color;
                end if;

                cursorCounter <= cursorCounter + 1;
              else
                cursorCounter <= 0;
              end if;
            when others =>
              Current_Size <= One;
          end case;
          --          

        when Command =>
          --   -- print command on LCD
          --LCD_data_TOP <= X"436F6D6D616E643A2020202020202020"; -- "Command: " in hex
          --   -- LCDoutput <= Command; -- convert to std_logic_vector in hex
          if kp_pulse = '1' then

            case CommandPress is
              when screenSize =>
                case keypress is
                  when X"31" =>
                    Resolution_Buffered <= Standard;
                    --current_state     <= Refresh;
                    LCD_data_TOP      <= X"436F6D6D616E643A2057312020202020"; -- "Command: S1" in hex
                    Resdisplay_Buffer <= X"31"; -- "1" in hex ASCII
                  when X"32" =>
                    Resolution_Buffered <= Twice;
                    LCD_data_TOP        <= X"436F6D6D616E643A2057322020202020"; -- "Command: S1" in hex
                    --current_state     <= Refresh;
                    Resdisplay_Buffer <= X"32"; -- "2" in hex ASCII
                  when X"0D" =>
                    Screen_Resolution <= Resolution_Buffered;
                    Resdisplay        <= Resdisplay_Buffer;
                    current_state     <= Refresh;
                  when X"08" =>
                    LCD_data_TOP <= X"436F6D6D616E643A2057202020202020";
                  when others =>
                    current_state <= Draw; -- Ignore other key presses and return to Draw state
                end case;

              when brushColor =>
                case keyPress is
                    -- Quick color shortcuts
                  when X"77" => color <= X"FFF";
                    colorVector         <= X"666666";
                    current_state       <= Draw; -- 'w' for white
                  when X"72" => color <= X"F00";
                    colorVector         <= X"663030";
                    current_state       <= Draw; -- 'r' for red
                  when X"67" => color <= X"0F0";
                    colorVector         <= X"306630";
                    current_state       <= Draw; -- 'g' for green
                    --                  when X"62" => color <= X"00F";
                    --                    colorVector         <= X"303066";
                    --                    current_state       <= Draw; -- 'b' for blue

                    -- Start manual hex input
                  when X"6D" => -- 'm' for manual
                    colorInputState    <= RED_INPUT;
                    colorVector_Buffer <= X"303030";
                    LCD_data_TOP       <= X"436F6D6D616E6420433A20" & colorVector_Buffer & X"2020"; -- "C: 000"

                  when X"08" =>
                    colorInputState    <= RED_INPUT;
                    colorVector_Buffer <= X"303030";
                    LCD_data_TOP       <= X"436F6D6D616E6420433A20" & X"303030" & X"2020";
                  when X"0D" =>
                    color           <= newColor;
                    colorVector     <= colorVector_Buffer;
                    current_state   <= Draw;
                    colorInputState <= IDLE;

                    -- Handle hex input based on current state
                  when others =>
                    case colorInputState is
                      when RED_INPUT =>
                        newColor(11 downto 8) <= ascii_to_4bit(keyPress);
                        colorVector_Buffer    <= keyPress & X"3030";
                        colorInputState       <= GREEN_INPUT;
                        LCD_data_TOP          <= X"436F6D6D616E6420433A20" & keyPress & X"3030" & X"2020"; -- "C:"

                      when GREEN_INPUT =>
                        newColor(7 downto 4) <= ascii_to_4bit(keyPress);
                        colorVector_Buffer   <= colorVector_Buffer(23 downto 16) & keyPress & X"30";
                        colorInputState      <= BLUE_INPUT;
                        LCD_data_TOP         <= X"436F6D6D616E6420433A20" & colorVector_Buffer(23 downto 16) & keyPress & X"30" & X"2020";

                      when BLUE_INPUT =>
                        newColor(3 downto 0) <= ascii_to_4bit(keyPress);
                        colorVector_Buffer   <= colorVector_Buffer(23 downto 8) & keyPress;
                        colorInputState      <= IDLE;
                        LCD_data_TOP         <= X"436F6D6D616E6420433A20" & colorVector_Buffer(23 downto 8) & keyPress & X"2020";

                        --                      when ENTER =>
                        ----                        LCD_data_TOP                   <= X"436F6D6D616E6420433A20" & colorVector_Buffer & X"2020";
                        --                        if keyPress = X"0D" then
                        --                          color           <= newColor;
                        --                          colorVector     <= colorVector_Buffer;
                        --                          current_state   <= Draw;
                        --                          colorInputState <= IDLE;
                        --                        end if;

                      when IDLE =>
                        --colorVector_Buffer <= X"303030";
                        -- Ignore extra keypresses
                        null;
                    end case;
                end case;

              when brushWidth =>
                case keypress is
                  when X"31" =>
                    Current_Size_Buffered <= One;
                    Brushdisplay_Buffer   <= X"31";
                    LCD_data_TOP          <= X"436F6D6D616E643A2053312020202020";
                    --                    if keypress = X"D0" then
                    --                      current_state <= Draw;
                    --                      Brushdisplay  <= X"31"; -- "1" in hex ASCII
                    --                      Current_Size  <= One;

                  when X"32" =>
                    Current_Size_Buffered <= Two;
                    Brushdisplay_Buffer   <= X"32";
                    LCD_data_TOP          <= X"436F6D6D616E643A2053322020202020";
                    --                    Current_Size  <= Two;
                    --                    current_state <= Draw;
                    --                    Brushdisplay  <= X"32"; -- "2" in hex ASCII
                  when X"33" =>
                    Current_Size_Buffered <= Three;
                    Brushdisplay_Buffer   <= X"33";
                    LCD_data_TOP          <= X"436F6D6D616E643A2053332020202020";
                    --                    Current_Size  <= Three;
                    --                    current_state <= Draw;
                    --                    Brushdisplay  <= X"33"; -- "3" in hex ASCII
                  when X"0D" =>
                    Current_Size  <= Current_Size_Buffered;
                    Brushdisplay  <= Brushdisplay_Buffer;
                    current_state <= Draw;
                  when X"08" =>
                    LCD_data_TOP <= X"436F6D6D616E643A2053202020202020";
                  when others =>
                    current_state <= Draw; -- Ignore other key presses and return to Draw state
                end case;

              when others =>
                current_state <= Draw; -- Fallback to Draw state if the command type is not recognized
            end case;
          end if; -- End of kp_pulse check

        when Write =>
          if kp_pulse = '1' then
            case keyPress is
              when X"09" =>
                current_state <= Draw; -- 'Tab' key to return to Draw state
              when others =>
                current_state <= Write; -- Ignore other key presses and return to Draw state
            end case;
          else
            current_state <= Write; -- Stay in Command state if no key press detected
          end if;
          --   -- print text on LCD
          LCD_data_TOP <= X"54657874202020202020202020202020"; -- "Text" in hex
          --   -- LCDoutput <= Text; -- convert to std_logic_vector in hex
        when others =>
          current_state <= Draw;
          -- print "Hardware Ready" on LCD
          -- LCDoutput <= "Hardware Ready"; -- convert to std_logic_vector in hex
      end case;

    end if;
  end process;

end Behavioral;