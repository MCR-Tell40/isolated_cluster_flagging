------------------------------------------------------------------------------------------
-- Bypass Flag FIFO 																	--
-- data width = 6, 4 downto 0 = #SPP in BCID, bit 5 = Bypass if high					--
-- Author: Nicholas Mead,																--
-- Referanced from: http://www.deathbylogic.com/2013/07/vhdl-standard-fifo/				--
-- Date: 18 Feb 2016																	--
------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity interface_fifo is
generic (
	constant DATA_WIDTH  	: 	positive := 6;
	constant FIFO_DEPTH	: 	positive := 32
);
port (
	clk, rst		: IN	std_logic;
	write_en		: IN	std_logic;
	read_en			: IN	std_logic;
	data_in			: IN	std_logic_vector (DATA_WIDTH - 1 downto 0);
	data_out		: OUT	std_logic_vector (DATA_WIDTH - 1 downto 0);
	empty			: OUT	std_logic;
	full			: OUT	std_logic
);
end interface_fifo;
 
architecture behavioural of interface_fifo is
begin
	-- Memory Pointer Process
	fifo_proc : process (clk)
		type fifo_memory is array (0 to FIFO_DEPTH - 1) of std_logic_vector (DATA_WIDTH - 1 downto 0);
		variable memory : fifo_memory;
		
		variable head 	: natural range 0 to FIFO_DEPTH - 1;
		variable tail 	: natural range 0 to FIFO_DEPTH - 1;
		variable looped : boolean;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				head 	:= 0;
				tail 	:= 0;
				
				looped 	:= false;
				
				full  	<= '0';
				empty 	<= '1';
			else
				if (read_en = '1') then
					if ((looped = true) or (head /= tail)) then
						-- Update data output
						data_out 	<= memory(tail);
						
						-- Update Tail pointer as needed
						if (tail = FIFO_DEPTH - 1) then
							tail 	:= 0;
							looped 	:= false;
						else
							tail 	:= tail + 1;
						end if;
					end if;
				end if;
				if (write_en = '1') then
					if ((looped = false) or (head /= tail)) then
						-- Write Data to Memory
						memory(head) 	:= data_in;
						
						-- Increment Head pointer as needed
						if (head = FIFO_DEPTH - 1) then
							head 	:= 0;
							looped 	:= true;
						else
							head 	:= head + 1;
						end if;
					end if;
				end if;
				-- Update empty and full flags
				if (head = tail) then
					if looped then
						full 	<= '1';
					else
						empty 	<= '1';
					end if;
				else
					empty	<= '0';
					full	<= '0';
				end if;
			end if;
		end if;
	end process;	
end behavioural;