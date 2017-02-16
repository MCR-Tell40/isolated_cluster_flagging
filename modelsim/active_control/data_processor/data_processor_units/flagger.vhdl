-- flagger.vhdl
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 09/02/2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.isolation_flagging_package.all;
use work.detector_constant_declaration.all;

entity flagger is
port(
   	rst 			: IN 	std_logic;	
   	clk			: IN 	std_logic;
   	data_in			: IN 	datatrain;
   	data_out		: OUT 	datatrain
);

end entity;

architecture a of flagger is
	shared variable inter_reg : datatrain;
begin
	process(clk, rst)
	begin
		if rst = '1' then
			data_out <= reset_pattern_train;
		elsif rising_edge(clk) then
			-- propagate first and last SPP - these are always edge cases, so not flagged
			inter_reg(0) 			:= data_in(0);
			inter_reg(MAX_FLAG_SIZE-1)	:= data_in(MAX_FLAG_SIZE-1);

			for i in 1 to (MAX_FLAG_SIZE - 2) loop
				-- if next SPP is all zeroes, must be edge case, so don't flag
				if (data_in(i+1) = x"00_00_00_00") then
					inter_reg(i) := data_in(i);
				else
					-- check if isolated by seeing if neighbouring BCID signals are present 
					if (to_integer(unsigned(data_in(i)(13 downto 8))) - to_integer(unsigned(data_in(i-1)(13 downto 8))) > 1) AND 
					(to_integer(unsigned(data_in(i+1)(13 downto 8))) - to_integer(unsigned(data_in(i)(13 downto 8))) > 1) then
						inter_reg(i) := data_in(i) OR x"80_00_00_00";
					else
						inter_reg(i) := data_in(i);
					end if;
				end if;
			end loop;
		end if;

		-- pass internal register to the output
		data_out <= inter_reg;
	end process;
end a;

