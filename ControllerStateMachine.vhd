library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity ControllerStateMachine is
  port (
    clk        : in std_logic;
    reset      : in std_logic;
    qx         : in std_logic;
    qy         : in std_logic;
    kp_pulse   : in std_logic;
    keyPress   : in std_logic;
    LCDoutput : out std_logic_vector(7 downto 0);
    color      : out std_logic_vector(11 downto 0);
    RAMaddress : out std_logic_vector(15 downto 0);
    RAMdata    : out std_logic_vector(11 downto 0)
  );
end ControllerStateMachine;

architecture Behavioral of ControllerStateMachine is
  -- Define state type
  type state_type is (Ready, Draw, Command, Text);
  signal current_state, next_state : state_type;
begin

  -- State transition process
  process (clk, reset)
  begin
    if reset = '1' then
        -- add logic for resetting the display
      current_state <= Draw;
    elsif rising_edge(clk) then
      current_state <= next_state;  
    end if;
  end process;

  -- Next state logic process
  process (current_state, keyPress, qx, qy)
  begin
    case current_state is
      when IDLE =>
        if input_signal = '1' then
          next_state <= STATE1;
        else
          next_state <= IDLE;
        end if;

      when STATE1 =>
        if input_signal = '1' then
          next_state <= STATE2;
        else
          next_state <= IDLE;
        end if;

      when STATE2 =>
        if input_signal = '1' then
          next_state <= STATE3;
        else
          next_state <= IDLE;
        end if;

      when STATE3 =>
        next_state <= IDLE;

      when others =>
        next_state <= IDLE;
    end case;
  end process;

  -- Output logic process
  process (current_state)
  begin
    case current_state is
      when IDLE =>
        output_signal <= '0';
      when STATE1 =>
        output_signal <= '0';
      when STATE2 =>
        output_signal <= '1';
      when STATE3 =>
        output_signal <= '1';
      when others =>
        output_signal <= '0';
    end case;
  end process;

end Behavioral;