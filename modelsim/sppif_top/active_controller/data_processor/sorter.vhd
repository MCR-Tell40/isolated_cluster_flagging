-- Bubble Sorter
-- This entity takes a datatrain input and outputs the datatrain one bubblesort iteration later.
-- Even defined by parity of LSB
-- Output is in descending order, highest BCID at top -- this is so padding 0's in datatrain are all at the bottom 
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 19/11/2015


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.detector_constant_declaration.all;	-- constants file
use work.sppif_package.all;			-- custom type definitions

entity sorter is
	port(  	clk, rst        : IN	std_logic; 
      		parity        	: IN	std_logic; -- high when odd
      		rd_data       	: IN	datatrain;
      		wr_data		: OUT	datatrain);
end entity;

architecture a of sorter is
	shared variable inter_reg	: datatrain; -- intermediate shift register
begin
	process(clk, rst)
	begin
		if rst = '1' then
			wr_data <= reset_pattern_train;
			inter_reg := reset_pattern_train;
		elsif rising_edge(clk) then
			for i in 0 to (MAX_FLAG_SIZE - 2) loop
				-- check even
				if ((i mod 2 = 1) AND (parity = '1')) OR ((i mod 2 = 0) AND (parity = '0')) then
					-- check if switch is required -- sorting by both Chip ID and column
					if (to_integer(unsigned(rd_data(i)(23 downto 14))) < to_integer(unsigned(rd_data(i + 1)(23 downto 14)))) then
						-- make switch
						inter_reg(i) 		:= rd_data(i + 1);
						inter_reg(i + 1) 	:= rd_data(i);
					else
						-- dont make switch
						inter_reg(i) 		:= rd_data(i);
						inter_reg(i + 1)	:= rd_data(i + 1); 
					end if;
				end if;
			end loop;

			if parity = '1' then
				inter_reg(0) := rd_data(0);
				inter_reg(MAX_FLAG_SIZE - 1) := rd_data(MAX_FLAG_SIZE - 1);
			end if;
			wr_data <= inter_reg;
		end if;
	end process;
end a;
