library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.AMC40_pack.all;
use work.Constant_Declaration.all;
use work.detector_constant_declaration.all;

library work;
use work.GDP_pack.all;

entity flagger is
	port(
		rst 			: in	std_logic;
   		clk			: in 	std_logic;
   		i_data			: in 	spp_array;
   		o_data			: out 	spp_array
	);
end entity;

architecture a of flagger is
	-- signals
	signal s_data 		: spp_array;

begin
	process(clk, rst)
	begin
		if rst = '1' then
			o_data <= (others => x"00000000");
		elsif rising_edge(clk) then
			-- propagate first and last SPP - these are always edge cases, so not flagged
			s_data(0) 				<= i_data(0);
			s_data(15)				<= i_data(15);

			for i in 1 to (14) loop
				-- if next spp is all zeroes, must be edge case, so don't flag
				if (i_data(i+1) = x"00000000") then
					s_data(i) <= i_data(i);
				else
					-- check if isolated by seeing if the columns to either side are empty
					if (to_integer(unsigned(i_data(i)(13 downto 8))) - to_integer(unsigned(i_data(i-1)(13 downto 8))) > 1) AND
					(to_integer(unsigned(i_data(i+1)(13 downto 8))) - to_integer(unsigned(i_data(i)(13 downto 8))) > 1) then
						-- cluster is isolated, flag by setting the MSB to 1
						s_data(i) <= i_data(i) OR x"80000000";
					else
						-- cluster is not isolated
						s_data(i) <= i_data(i);
					end if;
				end if;
			end loop;
		end if;

		-- pass internal register to the output
		o_data	<= s_data;
	end process;
end a;
