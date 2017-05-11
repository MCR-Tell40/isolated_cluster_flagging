--counter.vhd
-- 8 bit counter to keep track of number of clock cycles
-- Author D. Murray <donal.murray@cern.ch>
-- May 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.AMC40_pack.all;
use work.Constant_Declaration.all;
use work.detector_constant_declaration.all;
use work.GDP_pack.all;

entity counter is
	port(
		clk, rst, en	: in 	std_logic;
		o_count 	: out	std_logic_vector(7 downto 0)
	);
end entity;

architecture a of counter is
	-- intermediate shift register
	signal s_count	: 	std_logic_vector(7 downto 0);
begin
	o_count		<= s_count;

	process(clk, rst, en)
	begin
		if (rst = '1') then
			s_count		<= X"00";
		elsif (rising_edge(clk) and en = '0') then
			s_count 	<= X"00";
		elsif (rising_edge(clk) and en = '1') then
			s_count 	<= std_logic_vector(unsigned(s_count) + 1);
		end if;
	end process;
end a;
