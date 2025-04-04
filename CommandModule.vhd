library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CommandModule is
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        color   : out STD_LOGIC_VECTOR(2 downto 0);
        Resolution : out integer;
    );
end CommandModule;

architecture Behavioral of CommandModule is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            command_out <= (others => '0');
        elsif rising_edge(clk) then
            command_out <= command_in;
        end if;
    end process;
end Behavioral;