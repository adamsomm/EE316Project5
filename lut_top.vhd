library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity LUT_top is
    Port ( 
        iclk    : in STD_LOGIC;
        kb_code : in STD_LOGIC_vector(7 downto 0);
        keys: out std_logic_vector(6 downto 0);
        ubc_o   : out std_logic_vector(8 downto 0)
    );
end LUT_top;

architecture Behavioral of LUT_top is 
    signal ubc : std_logic_vector(8 downto 0);
begin

    process(iclk)
    begin
        if rising_edge(iclk) then
            case kb_code is 
                -- Uppercase Letters A-Z
                when "01000001" => ubc <= std_logic_vector(to_unsigned(8,9));    -- A
                when "01000010" => ubc <= std_logic_vector(to_unsigned(16,9));   -- B
                when "01000011" => ubc <= std_logic_vector(to_unsigned(24,9));   -- C
                when "01000100" => ubc <= std_logic_vector(to_unsigned(32,9));    -- D
                when "01000101" => ubc <= std_logic_vector(to_unsigned(40,9));    -- E
                when "01000110" => ubc <= std_logic_vector(to_unsigned(48,9));    -- F
                when "01000111" => ubc <= std_logic_vector(to_unsigned(56,9));    -- G
                when "01001000" => ubc <= std_logic_vector(to_unsigned(64,9));    -- H
                when "01001001" => ubc <= std_logic_vector(to_unsigned(72,9));    -- I
                when "01001010" => ubc <= std_logic_vector(to_unsigned(80,9));    -- J
                when "01001011" => ubc <= std_logic_vector(to_unsigned(88,9));    -- K
                when "01001100" => ubc <= std_logic_vector(to_unsigned(96,9));    -- L
                when "01001101" => ubc <= std_logic_vector(to_unsigned(104,9));   -- M
                when "01001110" => ubc <= std_logic_vector(to_unsigned(112,9));   -- N
                when "01001111" => ubc <= std_logic_vector(to_unsigned(120,9));   -- O
                when "01010000" => ubc <= std_logic_vector(to_unsigned(128,9));   -- P 
                when "01010001" => ubc <= std_logic_vector(to_unsigned(136,9));   -- Q 
                when "01010010" => ubc <= std_logic_vector(to_unsigned(144,9));   -- R 
                when "01010011" => ubc <= std_logic_vector(to_unsigned(152,9));   -- S
                when "01010100" => ubc <= std_logic_vector(to_unsigned(160,9));   -- T 
                when "01010101" => ubc <= std_logic_vector(to_unsigned(168,9));   -- U
                when "01010110" => ubc <= std_logic_vector(to_unsigned(176,9));   -- V
                when "01010111" => ubc <= std_logic_vector(to_unsigned(184,9));   -- W 
                when "01011000" => ubc <= std_logic_vector(to_unsigned(192,9));   -- X 
                when "01011001" => ubc <= std_logic_vector(to_unsigned(200,9));   -- Y 
                when "01011010" => ubc <= std_logic_vector(to_unsigned(208,9));   -- Z
                
                -- Numbers 0-9
                when "00110000" => ubc <= std_logic_vector(to_unsigned(384,9));  -- 0
                when "00110001" => ubc <= std_logic_vector(to_unsigned(392,9));   -- 1
                when "00110010" => ubc <= std_logic_vector(to_unsigned(400,9));   -- 2 
                when "00110011" => ubc <= std_logic_vector(to_unsigned(408,9));   -- 3
                when "00110100" => ubc <= std_logic_vector(to_unsigned(416,9));  -- 4 
                when "00110101" => ubc <= std_logic_vector(to_unsigned(424,9));  -- 5 
                when "00110110" => ubc <= std_logic_vector(to_unsigned(432,9));  -- 6 
                when "00110111" => ubc <= std_logic_vector(to_unsigned(440,9));  -- 7 
                when "00111000" => ubc <= std_logic_vector(to_unsigned(448,9));  -- 8 
                when "00111001" => ubc <= std_logic_vector(to_unsigned(452,9));  -- 9 
                
                -- Special characters
                when "00100000" => ubc <=  std_logic_vector(to_unsigned(256,9));  -- space 
                
                -- Default case
                when others => ubc <= (others => '0');
            end case;
        end if;
    end process;

    ubc_o <= ubc;

end Behavioral;