library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity ControllerStateMachine is
  port (
    clk      : in std_logic;
    reset    : in std_logic;
    qx       : in std_logic_vector(8 downto 0);
    qy       : in std_logic_vector(8 downto 0);
    kp_pulse : in std_logic;
    keyPress : in std_logic_vector(7 downto 0);
    -- LCDoutput  : out std_logic_vector(7 downto 0);
    -- color      : out std_logic_vector(11 downto 0);
    SETResolution : out integer := 256;
    RAMaddress    : out std_logic_vector(16 downto 0);
    RAMdata       : out std_logic_vector(11 downto 0)
  );
end ControllerStateMachine;

architecture Behavioral of ControllerStateMachine is
  -- Define state type
  type state_type is (Ready, Draw, Command, Text, Refresh);
  signal current_state : state_type;
  type Cursor_Size is (One, Two, Three);
  signal Current_Size : Cursor_Size := Three;
  type Screen_Size is (Standard, Double);
  signal Screen_Resulution : Screen_Size := Standard;
  type keyboard is (brushColor, brushWidth, screenSize);
  signal CommandPress : keyboard := brushColor;

  signal Resolution     : integer                       := 360;
  constant DefaultColor : std_logic_vector(11 downto 0) := X"FFF"; -- Default color for the display
  signal resetCount     : integer                       := 0;
  signal color          : std_logic_vector(11 downto 0) := X"F00";
  signal cursorCounter  : integer                       := 0;

begin
  SETResolution <= Resolution;
  -- Next state logic process
  process (current_state, qx, qy, clk, reset, kp_pulse)
    variable temp_addr  : unsigned(16 downto 0);
    variable x_unsigned : unsigned(8 downto 0);
    variable y_unsigned : unsigned(8 downto 0);
    constant MAX_Y      : unsigned(8 downto 0) := to_unsigned(Resolution - 1, 9);
    constant MAX_X      : unsigned(8 downto 0) := to_unsigned(Resolution - 1, 9);
    variable x_offset   : integer              := 0;
    variable y_offset   : integer              := 0;
  begin
    if reset = '1' then
      -- add logic for resetting the display
      current_state <= Refresh;
    elsif rising_edge(clk) then

      case current_state is

        when Refresh =>
          -- print "Refreshing" on LCD
          -- LCDoutput <= "Refreshing"; -- convert to std_logic_vector in hex
          if resetCount < Resolution ** 2 then
            RAMaddress <= std_logic_vector(to_unsigned(resetCount, RAMaddress'length));
            RAMdata    <= DefaultColor;
            resetCount <= resetCount + 1;
          else
            current_state <= draw;
            resetCount    <= 0; -- Reset the counter after filling the display
          end if;

        when Ready =>
          -- print "Hardware Ready" on LCD
          -- LCDoutput <= "Hardware Ready"; -- convert to std_logic_vector in hex
          current_state <= Draw;

        when Draw =>
          -- print "Drawing" on LCD
          -- LCDoutput <= "Drawing"; -- convert to std_logic_vector in hex

          if kp_pulse = '1' then
            case keyPress is
              when X"63" => -- Color command c
                CommandPress  <= brushColor; -- Change the command type to brushColor for next key press 
                current_state <= Command; -- Transition to Command state on key press pulse
              when X"77" => -- Screen Size Command s
                CommandPress  <= screenSize; -- Change the command type to screenSize for next key press
                current_state <= Command; -- Transition to Command state on key press pulse
              when X"73" => -- brush size Command w
                CommandPress  <= brushWidth; -- Change the command type to brushWidth for next key press
                current_state <= Command; -- Transition to Command state on key press pulse
              when others =>
                --ignore other keypresses
                current_state <= Draw; -- Stay in Draw state if the key is not recognized
            end case;
          end if;

          case Screen_Resulution is
            when Standard =>
              Resolution    <= 256; -- Standard resolution (now a signal)
              current_state <= Refresh;
            when Double =>
              Resolution    <= 360; -- Standard resolution (now a signal)
              current_state <= Refresh;
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
          --   -- LCDoutput <= Command; -- convert to std_logic_vector in hex
          if kp_pulse = '1' then

            case CommandPress is
              when screenSize =>
                case keypress is
                  when X"31" =>
                    Screen_Resulution <= Standard;
                    current_state     <= Draw;
                  when X"32" =>
                    Screen_Resulution <= Double;
                    current_state     <= Draw;
                  when others =>
                    current_state <= Draw; -- Ignore other key presses and return to Draw state
                end case;

              when brushColor =>
                case keypress is 
                  when X"67" => 
                    color <= X"0F0"; -- Green
                    current_state <= Draw;
                  when X"72" => 
                    color <= X"F00"; -- red
                    current_state <= Draw;
                  when X"62" =>
                    color <= X"00F"; -- Blue
                    current_state <= Draw;
                  when others => 
                    current_state <= Draw;
                end case;

              when brushWidth =>
                case keypress is
                  when X"31" =>
                    Current_Size  <= One;
                    current_state <= Draw;
                  when X"32" =>
                    Current_Size  <= Two;
                    current_state <= Draw;
                  when X"33" =>
                    Current_Size  <= Three;
                    current_state <= Draw;
                  when others =>
                    current_state <= Draw; -- Ignore other key presses and return to Draw state
                end case;
                
              when others =>
                current_state <= Draw; -- Fallback to Draw state if the command type is not recognized
            end case;
          end if; -- End of kp_pulse check

          -- when Text =>
          --   -- print text on LCD
          --   -- LCDoutput <= Text; -- convert to std_logic_vector in hex
        when others =>
          current_state <= Draw;
          -- print "Hardware Ready" on LCD
          -- LCDoutput <= "Hardware Ready"; -- convert to std_logic_vector in hex
      end case;
    end if;
  end process;

end Behavioral;