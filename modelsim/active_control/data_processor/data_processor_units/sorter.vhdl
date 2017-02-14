-- Bubble Sort Comparator
-- This entity takes a datatrain input and outputs the datatrain one bubblesort itteration later.
-- Even defined by parity of LSB
-- Output is in descending order, highest BCID at top -- this is so padding 0's in datatrain all at bottom 
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 19/11/2015


-- IEEE VHDL standard library:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.isolation_flagging_package.all;
use work.detector_constant_declaration.all;

entity bubble_sorter is
port(
   	clk, rst	: in 	std_logic;
   	parity 		: in 	std_logic; -- high if odd
   	data_in 	: in 	datatrain;
  	data_out	: out 	datatrain
);
end entity;

architecture a of bubble_sorter is
	shared variable inter_reg : datatrain; --intermediate shift register
begin
	process(clk, rst)
	begin
		if rst = '1' then
			data_out <= reset_pattern_train;
			inter_reg := reset_pattern_train;
		elsif rising_edge(clk) then
			for i in 0 to (MAX_FLAG_SIZE - 2) loop
				-- check even
				if ((i mod 2 = 1) AND (parity = '1')) OR ((i mod 2 = 0) AND (parity = '0')) then
					-- check if switch is required -- sorting by both Chip ID and column
					if (to_integer(unsigned(data_in(i)(23 downto 14))) < to_integer(unsigned(data_in(i + 1)(23 downto 14)))) then
						-- make switch
						inter_reg(i) 		:= data_in(i + 1);
						inter_reg(i + 1) 	:= data_in(i);
					else
						-- dont make switch
						inter_reg(i) 		:= data_in(i);
						inter_reg(i + 1)	:= data_in(i + 1); 
					end if;
				end if;
			end loop;

			if parity = '1' then
				inter_reg(0) := data_in(0);
				inter_reg(MAX_FLAG_SIZE - 1) := data_in(MAX_FLAG_SIZE - 1);
			end if;
			data_out <= inter_reg;
		end if;
	end process;
end a;