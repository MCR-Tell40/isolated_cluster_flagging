-- flagger.vhd
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 09/02/2016


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.detector_constant_declaration.all;	-- constants file
use work.sppif_package.all;			-- custom type definitions

entity flagger is
	port( 	rst 			: IN 	std_logic;	
   		clk			: IN 	std_logic;
   		rd_data			: IN 	datatrain;
   		wr_data			: OUT 	datatrain);
end entity;

architecture a of flagger is
begin
	process(clk, rst)
		variable inter_reg 	: 	datatrain;
	begin
		if rst = '1' then
			wr_data <= reset_pattern_train;
		elsif rising_edge(clk) then
			-- propagate first and last SPP - these are always edge cases, so not flagged
			inter_reg(0) 			:= rd_data(0);
			inter_reg(GWT_WIDTH - 1)	:= rd_data(GWT_WIDTH - 1);

			for i in 1 to (GWT_WIDTH - 2) loop
				-- if next SPP is all zeroes, must be edge case, so don't flag
				if (rd_data(i+1) = x"00_00_00_00") then
					inter_reg(i) := rd_data(i);
				else
					-- check if isolated by seeing if neighbouring BCID signals are present 
					if (to_integer(unsigned(rd_data(i)(13 downto 8))) - to_integer(unsigned(rd_data(i-1)(13 downto 8))) > 1) AND 
					(to_integer(unsigned(rd_data(i+1)(13 downto 8))) - to_integer(unsigned(rd_data(i)(13 downto 8))) > 1) then
						inter_reg(i) := rd_data(i) OR x"80_00_00_00";
					else
						inter_reg(i) := rd_data(i);
					end if;
				end if;
			end loop;
		end if;

		-- pass internal register to the output
		wr_data	<= inter_reg;
	end process;
end a;
