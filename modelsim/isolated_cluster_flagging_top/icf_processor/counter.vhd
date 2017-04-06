library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

library work;
use work.AMC40_pack.all;
use work.Constant_Declaration.all;
use work.detector_constant_declaration.all;

library work;
use work.GDP_pack.all;

entity counter is
	port(
		clk, rst, en	: in 	std_logic;
		o_count 		: out	std_logic_vector(7 downto 0)
	);
end entity;

architecture a of counter is
	-- intermediate shift register
	signal s_count	: 	std_logic_vector(75 - 1 downto 0);
begin
	o_count	<= s_count;

	process(clk, rst, en)
	begin
		if (rst = '1') then
			s_count	<= X"00";
		elsif (rising_edge(clk) and en = '1') then
			if (s_count = X"FF") then -- 255 is too high, should be 80 (x50) -- but anyway doesn't need to be here!
				s_count 	<= X"00";
			else
				s_count 	<= s_count + 1;
			end if;
		end if;
	end process;
end a;
