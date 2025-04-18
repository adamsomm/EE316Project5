
library IEEE;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_1164.ALL;  -- For std_logic and std_logic_vector types
use IEEE.STD_LOGIC_ARITH.ALL; -- For arithmetic operations on std_logic_vector
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- For unsigned operations (addition, subtraction, etc.)
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_lvl is
generic(N: integer := 9; N2: integer := 7; N1: integer := 0);
    Port ( 
           iclk         : in STD_LOGIC;
           c_code       : in STD_LOGIC_VECTOR(11 DOWNTO 0);
           ram_addr     : in std_logic_vector(16 downto 0);
--           ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
--           ps2_data     : IN  STD_LOGIC;
           ascii_out      : out std_logic_vector(6 downto 0);           
           reset        : in std_logic;
           ascii_newl   : in std_logic;
           ascii_code   : in std_logic_vector(7 downto 0) 

          );
end top_lvl;

architecture Behavioral of top_lvl is

component LUT_top is 
    port(
    
           iclk         : in STD_LOGIC;
           kb_code      : in STD_LOGIC_vector(7 downto 0);
           ubc_o        : out std_logic_vector(8 downto 0)
    );
end component; 
--------------------------------------------------------------------------------------------------
component counter8
  generic (
    N : integer;
    N2 : integer;
    N1 : integer
  );
  port (
    clk : in std_logic;
    reset : in std_logic;
    syn_clr : in std_logic;
    load : in std_logic;
    en : in std_logic;
    up : in std_logic;
    clk_en : in std_logic;
    d : in std_logic_vector(N-1 downto 0);
    max_tick : out std_logic;
    min_tick : out std_logic;
    q : out std_logic_vector(N-1 downto 0)
  );
end component;
component univ_bin_counter is 
 generic(N: integer := 9; N2: integer := 511; N1: integer := 0);
   port(
			clk, reset				: in std_logic;
			syn_clr, load, en, up	: in std_logic;
			clk_en 					: in std_logic := '1';			
			d						: in std_logic_vector(N-1 downto 0);
			max_tick, min_tick		: out std_logic;
			q						: out std_logic_vector(N-1 downto 0)		
   );
end component;
--------------------------------------------------------------------------------------------------------
component blk_mem_gen_1 is 
port(
    addra   :in std_logic_vector(8 downto 0);
    clka    :in std_logic;
    douta   :out std_logic_vector(7 downto 0)
);
end component;
--------------------------------------------------------------------------------------------------------

--component matt_ram is 
--port(
--    addra   :in std_logic_vector(16 downto 0);
--    clka    :IN STD_LOGIC;
--    dina    :in std_logic_vector(11 downto 0);
--    wea     :in std_logic_vector(0 downto 0);
    
--    addrb   :in std_logic_vector(16 downto 0);
--    clkb    :IN STD_LOGIC;
--    doutb   :OUT std_logic_vector(11 downto 0)

--);
--end component;
--------------------------------------------------------------------------------------------------------
component dummy_ram is 
port(
    addra   :in std_logic_vector(6 downto 0);
    clka    :IN STD_LOGIC;
    dina    :in std_logic_vector(11 downto 0);
    wea     :in std_logic_vector(0 downto 0);
    
    addrb   :in std_logic_vector(6 downto 0);
    clkb    :IN STD_LOGIC;
    doutb   :OUT std_logic_vector(11 downto 0)

);
end component ;
--------------------------------------------------------------------------------------------------------

--component ps2_keyboard_to_ascii is 
--PORT(
--      clk        : IN  STD_LOGIC;                     --system clock input
--      ps2_clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
--      ps2_data   : IN  STD_LOGIC;                     --data signal from PS2 keyboard
--      ascii_new  : OUT STD_LOGIC;                     --output flag indicating new ASCII value
--      ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
--      ); --ASCII value
--end component;
--------------------------------------------------------------------------------------------------------
signal temp: std_logic_vector(8 downto 0);

signal q3 : std_logic_vector(8 downto 0);
signal q2 : std_logic_vector(8 downto 0);
--signal q22: std_logic_vector(9 downto 0);
signal q1 : std_logic_vector(8 downto 0);
signal q_prev : std_logic_vector(8 downto 0);

signal d1: std_logic_vector(8 downto 0);
signal d2: std_logic_vector(8 downto 0);
signal ld3: std_logic;
type statetype is (count,store_arr,store_ram,store_dummy,read_dummy);
signal state: statetype:=count; 

signal en1 :std_logic:='0' ;
signal en2 :std_logic:='0' ;
signal en3 :std_logic:='0';

signal dummy_o:std_logic_vector(11 downto 0);
signal ram_o:std_logic_vector(11 downto 0);
signal rom_data: std_logic_vector(7 downto 0);
--signal ascii_newl: STD_LOGIC;  
signal ubc_o:std_logic_vector(8 downto 0);
signal ascii_code1:STD_LOGIC_VECTOR(7 DOWNTO 0);

signal cnt:integer:=0;
signal cntr:integer:=0;
signal index:integer:=0;
signal douta:std_logic_vector(7 downto 0);
signal color:std_logic_vector(11 downto 0);
type arr is array (7 downto 0) of std_logic_vector(11 downto 0);
signal col_arr : arr;

signal ram_q_addr   :std_logic_vector(16 downto 0);
signal ram_addr2   :std_logic_vector(16 downto 0);
signal delay_counter : integer := 0;  -- Delay counter
signal delay_value   : integer := 1; -- Number of clock cycles for de
signal done : std_logic:='1';
signal done2 : std_logic:='1';
signal done3 : std_logic:='1';

signal q3_prev : std_logic_vector(8 downto 0);
signal jclk:std_logic;
signal jclk_cnt:integer:=0;
signal jclk_cnt_max:integer:=624;
signal int :integer;
signal rom_cnt :integer:=0;
signal romy_cnt :integer:=0;
signal tempi:integer;
signal cntx:integer:=0;

signal enter:std_logic_vector(0 downto 0);
begin
ram_q_addr<="00000000"&q2;
ram_addr2<=ram_addr+ram_q_addr; 

--ascii_out<=ascii_code1;



------tmp---
ascii_code1<=ascii_code;
process(iclk,q1)
begin 

case state is 
when count=> 

en1<='1';
if ascii_newl='1' then
temp<=q1+"00000111";
end if;
if q1=temp then 
en1<='0';
end if;

   if rising_edge(iclk) then   
     if iclk = '1' then      
       state <=store_arr;
      end if;
   end if;
  
    
when store_arr => 
 en1<='0';

  if rising_edge(iclk) then
            if delay_counter < delay_value then
                delay_counter <= delay_counter + 1;
            else
                
                    for i in rom_data'range loop
                        if rom_data(i) = '0' then 
                            col_arr(i) <= X"FFF"; 
                        else 
                            col_arr(i) <= c_code; 
                        end if;
                        
                        
                    end loop;
                -- Reset the counter after the delay
                delay_counter <= 0;
                state <=store_dummy;
            end if;
        end if;
when store_dummy =>

         if rising_edge(iclk) then
           
            if jclk = '1' then  
                if col_arr(7)(11)/='U' then --or col_arr(7)(11)='0' then 
                    if cnt < 8 and done2 = '1' then
                    
                        cnt <= cnt + 1;  
                         en3<='1';
                     color <= col_arr(cnt);  -- Assign color based on counter value                  

                else
                    cnt <= 0; 
                    done<='0';
                    en3<='0';
                    state<=count; 
                end if;
            end if;
        end if;
        end if;
        if cntr /=7 then 
       cntr<=cntr+1;
       state<=count;

        end if; 
   if ascii_code="00001101" then
enter<="1";
state<=read_dummy;
end if;   

          
when read_dummy=>
if rising_edge(iclk) then
           
            if jclk = '1' then  
                if cntx < 1536 and done3 = '1' then
                    cntx <= cntx + 1;  
                     en2<='1';                    
                else
                    cntx <= 0; 
                    done3<='0';
                    en2<='0';
                    state<=count; 
                end if;
            end if;
        end if;

when others => null;
end case;
end process;
clk_div: process(iclk)
begin
	if rising_edge(iclk)then
			
			if (jclk_cnt= jclk_cnt_max) then
				jclk_cnt <= 0;
				jclk <= '1';
			else
				jclk_cnt <= jclk_cnt + 1;
				jclk <= '0';
			end if;
	end if;

end process;
--process(iclk,c_code)
--begin
--if rising_edge(iclk) then 
--red<=c_code(11 downto 8);
--green<=c_code(7 downto 4);
--blue<=c_code(3 downto 0);
--end if;
--end process;

ubc_to_rom: univ_bin_counter
  port map(
			clk      =>  iclk,
			reset    =>  reset,
			syn_clr  =>  '0',
			load     =>  ascii_newl, --from keyboard 2 ascii 
			en       =>  en1,
			up       =>  '1',
			clk_en   =>  '1',					
			d        =>	 ubc_o,					
			max_tick =>  open,
			min_tick =>  open,		
			q        =>  q1	-- chooses the index for a letter 			
   );
  --------------------------------------------------------------------------------------------------------

ubc_to_ram: univ_bin_counter
port map(
            clk      =>  iclk,
			reset    =>  reset,
			syn_clr  =>  '0',
			load     =>  '0',
			en       =>  en2,
			up       =>  '1',
			clk_en   =>  '1',					
			d        =>	  d2,					
			max_tick =>  open,
			min_tick =>  open,		
			q        =>  q2		
);
--------------------------------------------------------------------------------------------------------

counter8_inst : counter8
  generic map (
    N => N,
    N2 => N2,
    N1 => N1
  )
  port map (
    clk => iclk,
    reset => reset,
    syn_clr => '0',
    load => '0',
    en => en3,
    up => '1',
    clk_en => jclk,
    d => d1,
    max_tick => open,
    min_tick => open,
    q => q3
  );

--------------------------------------------------------------------------------------------------------


rom: blk_mem_gen_1
port map(
            addra    =>  q1, 
            clka     =>  iclk, 
            douta    =>  rom_data
);
--------------------------------------------------------------------------------------------------------

--ram: matt_ram
--port map (
--            addra    =>  ram_addr2,
--            clka     =>  iclk,
--            dina     =>  dummy_o,
--            wea      =>  "1",           
--            addrb   =>  ram_addr2,
--            clkb    =>iclk,
--            doutb   =>ram_o
--);
--------------------------------------------------------------------------------------------------------
Dummy: dummy_ram
port map (
            addra    =>  q3(6 downto 0),
            clka     =>  iclk,
            dina     =>  color,
            wea      =>  enter,  -- enter=0 ( wea=1 means data is being writen to the RAM)         
            addrb   =>   q3(6 downto 0),--have a seperate coutner to iterate trgouh th dummy to print           
            clkb    =>iclk,
            doutb   =>dummy_o


);
--------------------------------------------------------------------------------------------------------

--keyboard: ps2_keyboard_to_ascii
--port map(
--      clk        => iclk,
--      ps2_clk    => ps2_clk,
--      ps2_data   => ps2_data,
--      ascii_new  => ascii_newl,
--      ascii_code => ascii_code1
      

--);
--------------------------------------------------------------------------------------------------------
LUT: lut_top
port map(

           iclk      => iclk,
           kb_code   => ascii_code,
           ubc_o     =>  ubc_o
);
end Behavioral;
