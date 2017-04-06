-- flagger.vhd
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 09/02/2016


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.detector_constant_declaration.all;	-- constants file

entity flagger is
	port(
   		clk			: IN 	std_logic;
			rst 			: IN 	std_logic;
   		rd_data		: IN 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
   		wr_data		: OUT std_logic_vector(DATA_WORD_SIZE - 1 downto 0)
	);
end entity;

architecture a of flagger is
		signal inter_reg 	: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
				wr_data	<= inter_reg;
begin
	process(clk, rst)
		if rst = '1' then
			inter_reg <= (others => 0);
		elsif rising_edge(clk) then
			-- propagate first and last SPP - these are always edge cases, so not flagged
			inter_reg(0) 			:= rd_data(0);
			inter_reg(MAX_ADDR - 1)	:= rd_data(MAX_ADDR - 1);

			for i in 1 to (MAX_ADDR - 2) loop
				-- if next SPP is all zeroes, must be edge case, so don't flag
				if (rd_data(i+1) = x"00_00_00_00") then
					inter_reg(i) <= rd_data(i);
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
	end process;
end a;
