library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity ControllerStateMachine is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    qx    : in std_logic_vector(7 downto 0);
    qy    : in std_logic_vector(7 downto 0);
    -- kp_pulse   : in std_logic;
    -- keyPress   : in std_logic;
    -- LCDoutput  : out std_logic_vector(7 downto 0);
    -- color      : out std_logic_vector(11 downto 0);
    RAMaddress : out std_logic_vector(15 downto 0);
    RAMdata    : out std_logic_vector(11 downto 0)
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

  signal Resolution     : integer                       := 256;
  constant DefaultColor : std_logic_vector(11 downto 0) := X"FFF"; -- Default color for the display
  signal resetCount     : integer                       := 0;
  signal color          : std_logic_vector(11 downto 0) := X"F00";
  signal cursorCounter  : integer                       := 0;

begin
  -- Next state logic process
  process (current_state, qx, qy, clk, reset)
    variable temp_addr  : unsigned(15 downto 0) := X"FF00";
    variable x_unsigned : unsigned(7 downto 0)  := X"00";
    variable y_unsigned : unsigned(7 downto 0)  := X"F0";
    constant MAX_Y      : unsigned(7 downto 0)  := to_unsigned(Resolution - 1, 8);
    constant MAX_X      : unsigned(7 downto 0)  := to_unsigned(Resolution - 1, 8);
    variable x_offset   : integer               := 0;
    variable y_offset   : integer               := 0;
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
          -- case Screen_Resulution is
          --   when Standard =>
          --     Resolution    <= 256; -- Standard resolution (now a signal)
          --     current_state <= Refresh;
          --   when Double =>
          -- end case;
          case Current_Size is --  prints different sized cursors 
            when One =>
              -- print "Cursor Size 1" on LCD
              -- LCDoutput <= "Cursor Size 1"; -- convert to std_logic_vector in hex
              x_unsigned := unsigned(qx);
              y_unsigned := MAX_Y - unsigned(qy);
              temp_addr  := y_unsigned & x_unsigned;

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
                  temp_addr  := y_unsigned & x_unsigned;
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
                  temp_addr  := y_unsigned & x_unsigned;
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

          -- when Command =>
          --   -- print command on LCD
          --   -- LCDoutput <= Command; -- convert to std_logic_vector in hex
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