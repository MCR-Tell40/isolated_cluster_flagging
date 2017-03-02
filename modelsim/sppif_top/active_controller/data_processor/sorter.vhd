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
	signal inter_reg	: datatrain; -- intermediate shift register

begin
	process(clk, rst)
	begin
		if rst = '1' then
			wr_data <= reset_pattern_train;
			inter_reg <= reset_pattern_train;
		elsif rising_edge(clk) then
			for i in 0 to (GWT_WIDTH - 2) loop
				if ((i mod 2 = 0) AND (parity = '0')) then
					-- even pass - compare 0 with 1, 2 with 3 etc
					-- check if switch is required -- sorting by both Chip ID and column
					if (to_integer(unsigned(rd_data(i)(23 downto 14))) < to_integer(unsigned(rd_data(i + 1)(23 downto 14)))) then
						-- make switch
						inter_reg(i) 		<= rd_data(i + 1);
						inter_reg(i + 1) 	<= rd_data(i);
					else
						-- dont make switch
						inter_reg(i) 		<= rd_data(i);
						inter_reg(i + 1)	<= rd_data(i + 1);
					end if;
				elsif ((i mod 2 = 1) AND (parity = '1')) then
					-- odd pass compare 1 with 2, 3 with 4 etc
					-- check if switch is required -- sorting by both Chip ID and column
					if (i = GWT_WIDTH - 2) then
						-- at max bit, do not change end bits
						inter_reg(0) <= rd_data(0);
						inter_reg(GWT_WIDTH - 1) <= rd_data(GWT_WIDTH - 1);
					else
						if (to_integer(unsigned(rd_data(i + 1)(23 downto 14))) < to_integer(unsigned(rd_data(i + 2)(23 downto 14)))) then
							-- make switch
							inter_reg(i + 1) 	<= rd_data(i + 2);
							inter_reg(i + 2) 	<= rd_data(i + 1);
						else
							-- dont make switch
							inter_reg(i + 1) 	<= rd_data(i + 1);
							inter_reg(i + 2)	<= rd_data(i + 2);
						end if;
					end if;
				end if;
			end loop;
			wr_data <= inter_reg;
		end if;
	end process;
end a;
