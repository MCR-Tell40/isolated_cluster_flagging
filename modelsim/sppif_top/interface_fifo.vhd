

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.detector_constant_declaration.all;	-- constants file
use work.sppif_package.all;			-- custom type definitions

entity interface_fifo is
	port (	clk, rst		: IN	std_logic;
		empty, full		: OUT	std_logic;

		-- from active controller
		wr_en			: IN	std_logic;
		wr_data			: IN	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);

		-- to bypass controller
		rd_en			: IN	std_logic;
		rd_data			: OUT	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0));
end interface_fifo;
 
architecture behavioural of interface_fifo is
begin
	-- Memory Pointer Process
	fifo_proc : process (clk)
		variable memory 	: fifo_memory;
		variable head 		: natural range 0 to FIFO_DEPTH - 1;
		variable tail 		: natural range 0 to FIFO_DEPTH - 1;
		variable looped		: boolean;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				head 	:= 0;
				tail 	:= 0;
				looped 	:= false;
				
				full  	<= '0';
				empty 	<= '1';
			else
				if (rd_en = '1') then
					if ((looped = true) or (head /= tail)) then
						-- Update data output
						rd_data 	<= memory(tail);
						
						-- Update Tail pointer as needed
						if (tail = FIFO_DEPTH - 1) then
							-- tail at end, reset to 0
							tail 	:= 0;
							looped 	:= false;
						else
							-- still not at end, increment
							tail 	:= tail + 1;
						end if;
					end if;
				end if;
				if (wr_en = '1') then
					if ((looped = false) or (head /= tail)) then
						-- Write Data to Memory
						memory(head) 	:= wr_data;
						
						-- Increment Head pointer as needed
						if (head = FIFO_DEPTH - 1) then
							-- head at end, reset to 0
							head 	:= 0;
							looped 	:= true;
						else
							-- still not at end, increment
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