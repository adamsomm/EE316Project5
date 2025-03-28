library ieee;
use ieee.std_logic_1164.all;

entity StateMachine is
    PORT (  
        A: in std_logic;
        B: in std_logic;
        reset_n: in std_logic;
        clock: in std_logic;
        up: out std_logic; 
        en: out std_logic  -- Z
    );
end StateMachine;

architecture Behavioral of StateMachine is
    type State_type is (INIT, R1, R2, R3, L1, L2, L3, UPs, DWN);
    signal CS: State_type;  -- Current State
begin

    -- State transition process
    process(clock, reset_n)
    begin
        if reset_n = '1' then
            CS <= INIT;  -- Reset state
        elsif rising_edge(clock) then
            case CS is
                when INIT => 
                    if (A = '0') then 
                        CS <= R1;
                    elsif (B = '0') then
                        CS <= L1;
                    else
                        CS <= INIT;  -- Stay in INIT if no conditions met
                    end if;

                when R1 => 
                    if (B = '0') then 
                        CS <= R2;
                    elsif (A = '1') then
                        CS <= INIT;
                    else
                        CS <= R1;  -- Stay in R1 if no conditions met
                    end if;

                when R2 => 
                    if (A = '1') then 
                        CS <= R3;
                    elsif (B = '1') then
                        CS <= R1;
                    else
                        CS <= R2;  -- Stay in R2 if no conditions met
                    end if;

                when R3 => 
                    if (B = '1') then 
                        CS <= UPs;
                    elsif (A = '0') then
                        CS <= R2;
                    else
                        CS <= R3;  -- Stay in R3 if no conditions met
                    end if;

                when L1 => 
                    if (A = '0') then 
                        CS <= L2;
                    elsif (B = '1') then
                        CS <= INIT;
                    else
                        CS <= L1;  -- Stay in L1 if no conditions met
                    end if;

                when L2 => 
                    if (B = '1') then 
                        CS <= L3;
                    elsif (A = '1') then
                        CS <= L1;
                    else
                        CS <= L2;  -- Stay in L2 if no conditions met
                    end if;

                when L3 => 
                    if (A = '1') then 
                        CS <= DWN;
                    elsif (B = '0') then
                        CS <= L2;
                    else
                        CS <= L3;  -- Stay in L3 if no conditions met
                    end if;

                when UPs => 
                    CS <= INIT;  -- Transition back to INIT

                when DWN => 
                    CS <= INIT;  -- Transition back to INIT

                when others => 
                    CS <= INIT;  -- Default to INIT on unexpected states
            end case;
        end if;
    end process;

    -- Output logic
    process(CS)
    begin
        case CS is 
            when INIT =>
                en <= '0';
                up <= '0';
            when UPs =>
                en <= '1';
                up <= '1';
            when DWN =>
                en <= '1';
                up <= '0';
            when others =>
                en <= '0';
                up <= '0';
        end case;
    end process;

end Behavioral;