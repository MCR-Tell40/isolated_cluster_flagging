--split_datatrain.vhd
-- split a datatrain into its 8 constituent 32bit SPPs


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.detector_constant_declaration.all;	-- constants file
use work.sppif_package.all;			-- custom type definitions

entity split_datatrain is
	port(	rst		: IN	std_logic;	-- reset
		rd_data		: IN	datatrain;	-- 128 x 1 32bit SPPs
		wr_data		: OUT	datatrain_wr);	-- 8 x 16 32bit SPPs
end split_datatrain;

architecture a of split_datatrain is
	signal inter_reg	: datatrain_wr;	-- internal register for manipulation
begin
	process(rst)
	begin
		if rst = '1' then
			-- reset internal register (fill with zeroes)
			inter_reg	<= reset_pattern_wrtrain;
		else
			-- load rd_data into inter_reg, split up into individual SPPs
			for i in 0 to 7 loop
				for j in 0 to 7 loop
					inter_reg(i)((32 * (j + 1)) - 1 downto 32 * j)	<= rd_data(16 * i + j);
				end loop;
			end loop;
		end if;
		-- load inter_reg into wr_data to output
		wr_data		<= inter_reg;
	end process;
end architecture;
