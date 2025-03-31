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
  signal current_state, next_state : state_type;
  type Cursor_Size is (One, Two, Three);
  signal Current_Size : Cursor_Size := One;

  constant Resolution   : integer                       := 256;
  constant DefaultColor : std_logic_vector(11 downto 0) := X"FFF"; -- Default color for the display
  signal resetCount     : integer                       := 0;
  signal color          : std_logic_vector(11 downto 0) := X"F00";
  signal cursorCounter  : integer                       := 0;

begin

  -- State transition process
  process (clk, reset)
  begin
    if reset = '1' then
      -- add logic for resetting the display
      current_state <= Refresh;
    elsif rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process;

  -- Next state logic process
  process (current_state, qx, qy, clk, reset)
    variable temp_addr  : unsigned(15 downto 0);
    variable x_unsigned : unsigned(7 downto 0);
    variable y_unsigned : unsigned(7 downto 0);
    constant MAX_Y      : unsigned(7 downto 0) := to_unsigned(Resolution - 1, 8);
  begin
    case current_state is

      when Refresh =>
        -- print "Refreshing" on LCD
        -- LCDoutput <= "Refreshing"; -- convert to std_logic_vector in hex
        if resetCount < Resolution ** 2 then
          RAMaddress <= std_logic_vector(to_unsigned(resetCount, RAMaddress'length));
          RAMdata    <= DefaultColor;
          resetCount <= resetCount + 1;
        else
          next_state <= draw;
          resetCount <= 0; -- Reset the counter after filling the display
        end if;

      when Ready =>
        -- print "Hardware Ready" on LCD
        -- LCDoutput <= "Hardware Ready"; -- convert to std_logic_vector in hex
        next_state <= Draw;

      when Draw =>
        -- print "Drawing" on LCD
        -- LCDoutput <= "Drawing"; -- convert to std_logic_vector in hex
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
            -- print "Cursor Size 2" on LCD
            -- LCDoutput <= "Cursor Size 2"; -- convert to std_logic_vector in hex
            if cursorCounter < 4 then
              -- Increment cursorCounter and adjust x/y for the next pixel
              case cursorCounter is
                when 0 =>
                  x_unsigned := unsigned(qx);
                  y_unsigned := MAX_Y - unsigned(qy);
                  temp_addr  := y_unsigned & x_unsigned;
                when 1 =>
                  x_unsigned := unsigned(qx) + 1; -- Move right for the next pixel
                  y_unsigned := MAX_Y - unsigned(qy);
                  temp_addr  := y_unsigned & x_unsigned;
                when 2 =>
                  x_unsigned := unsigned(qx);
                  y_unsigned := MAX_Y - unsigned(qy) + 1; -- Move up for the next pixel
                  temp_addr  := y_unsigned & x_unsigned;
                when 3 =>
                  x_unsigned := unsigned(qx) + 1; -- Move right for the next pixel
                  y_unsigned := MAX_Y - unsigned(qy) + 1; -- Move up for the next pixel
                  temp_addr  := y_unsigned & x_unsigned;
                when others =>
                  x_unsigned := unsigned(qx);
                  y_unsigned := MAX_Y - unsigned(qy);
                  temp_addr  := y_unsigned & x_unsigned;
              end case;
              -- Output assignments
              RAMaddress    <= std_logic_vector(temp_addr);
              RAMdata       <= color;
              cursorCounter <= cursorCounter + 1;
            else
              cursorCounter <= 0; -- Reset counter after drawing the 2x2 block
            end if;

            -- when Three =>
            -- print "Cursor Size 3" on LCD
            -- LCDoutput <= "Cursor Size 3"; -- convert to std_logic_vector in hex
        end case;

        -- when Command =>
        --   -- print command on LCD
        --   -- LCDoutput <= Command; -- convert to std_logic_vector in hex
        -- when Text =>
        --   -- print text on LCD
        --   -- LCDoutput <= Text; -- convert to std_logic_vector in hex
      when others =>
        next_state <= Draw;
        -- print "Hardware Ready" on LCD
        -- LCDoutput <= "Hardware Ready"; -- convert to std_logic_vector in hex
    end case;
  end process;

  -- Output logic process
  -- process (clk, current_state)
  --   variable temp_addr  : unsigned(15 downto 0);
  --   variable x_unsigned : unsigned(7 downto 0);
  --   variable y_unsigned : unsigned(7 downto 0);
  --   constant MAX_Y      : unsigned(7 downto 0) := to_unsigned(Resolution - 1, 8);
  -- begin
  --   case current_state is
  --     when Ready =>
  --       -- print "Hardware Ready" on LCD
  --       -- LCDoutput <= "Hardware Ready"; -- convert to std_logic_vector in hex
  --       next_state <= Draw;
  --     when Draw =>
  --       -- print "Drawing" on LCD
  --       -- LCDoutput <= "Drawing"; -- convert to std_logic_vector in hex
  --       --case that will be used to print larger cursors 
  --       case Current_Size is
  --         when One =>
  --           -- print "Cursor Size 1" on LCD
  --           -- LCDoutput <= "Cursor Size 1"; -- convert to std_logic_vector in hex
  --           x_unsigned := unsigned(qx);
  --           y_unsigned := MAX_Y - unsigned(qy);
  --           temp_addr  := y_unsigned & x_unsigned;

  --           -- Output assignments
  --           RAMaddress <= std_logic_vector(temp_addr);
  --           RAMdata    <= color;
  --         when Two =>
  --           -- print "Cursor Size 2" on LCD
  --           -- LCDoutput <= "Cursor Size 2"; -- convert to std_logic_vector in hex
  --           if cursorCounter < 4 then
  --             -- Increment cursorCounter and adjust x/y for the next pixel
  --             case cursorCounter is
  --               when 0 =>
  --                 x_unsigned := unsigned(qx);
  --                 y_unsigned := MAX_Y - unsigned(qy);
  --                 temp_addr  := y_unsigned & x_unsigned;
  --               when 1 =>
  --                 x_unsigned := unsigned(qx) + 1; -- Move right for the next pixel
  --                 y_unsigned := MAX_Y - unsigned(qy);
  --                 temp_addr  := y_unsigned & x_unsigned;
  --               when 2 =>
  --                 x_unsigned := unsigned(qx);
  --                 y_unsigned := MAX_Y - unsigned(qy) + 1; -- Move up for the next pixel
  --                 temp_addr  := y_unsigned & x_unsigned;
  --               when 3 =>
  --                 x_unsigned := unsigned(qx) + 1; -- Move right for the next pixel
  --                 y_unsigned := MAX_Y - unsigned(qy) + 1; -- Move up for the next pixel
  --                 temp_addr  := y_unsigned & x_unsigned;
  --               when others =>
  --                 x_unsigned := unsigned(qx);
  --                 y_unsigned := MAX_Y - unsigned(qy);
  --                 temp_addr  := y_unsigned & x_unsigned;
  --             end case;
  --             -- Output assignments
  --             RAMaddress    <= std_logic_vector(temp_addr);
  --             RAMdata       <= color;
  --             cursorCounter <= cursorCounter + 1;
  --           else
  --             cursorCounter <= 0; -- Reset counter after drawing the 2x2 block
  --           end if;

  --           -- when Three =>
  --           -- print "Cursor Size 3" on LCD
  --           -- LCDoutput <= "Cursor Size 3"; -- convert to std_logic_vector in hex
  --       end case;

  --       -- when Command =>
  --       --   -- print command on LCD
  --       --   -- LCDoutput <= Command; -- convert to std_logic_vector in hex
  --       -- when Text =>
  --       --   -- print text on LCD
  --       --   -- LCDoutput <= Text; -- convert to std_logic_vector in hex
  --     when Refresh =>
  --       -- print "Refreshing" on LCD
  --       -- LCDoutput <= "Refreshing"; -- convert to std_logic_vector in hex

  --     when others =>
  --       -- print "Hardware Ready" on LCD
  --       -- LCDoutput <= "Hardware Ready"; -- convert to std_logic_vector in hex
  --   end case;
  -- end process;

end Behavioral;