--construct_datatrain.vhd
-- combine input signals and pad with zeroes to form a datatrain

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.detector_constant_declaration.all;	-- constants file
use work.eif_package.all;			-- custom type definitions

entity construct_datatrain is
port(
	rst		: IN	std_logic;	-- reset
	rd_data		: IN	datatrain_rd;	-- 8 x 16 24bit SPP 	input
	wr_data		: OUT	datatrain	-- 128 x 1 32bit SPP	output
);
end construct_datatrain;

architecture a of construct_datatrain is
	signal inter_reg	: datatrain;	-- internal register for manipulation
begin
	process(rst)
	begin
		if rst = '1' then
			-- reset internal register (fill with zeroes)
			inter_reg	<= reset_pattern_train;
		else
			-- load rd_data into inter_reg, split up and pad with zeroes to make a 32bit SPP
			for i in 0 to 7 loop
				for j in 0 to 15 loop
					inter_reg(16 * i + j) <= "00000000" & rd_data(i)(24 * (j + 1) - 1 downto 24 * j);
				end loop;
			end loop;
		end if;
		-- load inter_reg into wr_data to output
		wr_data		<= inter_reg;
	end process;
end architecture;

