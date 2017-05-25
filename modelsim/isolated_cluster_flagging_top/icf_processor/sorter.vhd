--sorter.vhd
-- Bubble sort implementation in VHDL
-- Sorts SPPs spatially by column and chip ID -- performs one switch and returns
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

entity sorter is
	port(
	        clk, rst        : IN	std_logic;
		en		: IN	std_logic;
	      	odd         	: IN	std_logic; -- high when odd
	      	i_data       	: IN	spp_array;
	      	o_data		: OUT	spp_array
	);
end entity;

architecture a of sorter is
	signal s_data	: spp_array; -- intermediate shift register

begin
	process(clk, rst)
	begin
		if rst = '1' then
			o_data <= (others => (others => '0'));
			s_data <= (others => (others => '0'));
		elsif rising_edge(clk) and en = '1' then
			for i in 0 to 62 loop
				if ((i mod 2 = 0) AND (odd = '0')) then
					-- even pass - compare 0 with 1, 2 with 3 etc
					-- check if switch is required -- sorting by both Chip ID and column
					if (to_integer(unsigned(i_data(i)(23 downto 14))) < to_integer(unsigned(i_data(i + 1)(23 downto 14)))) then
						-- make switch
						s_data(i) 		<= i_data(i + 1);
						s_data(i + 1) 		<= i_data(i);
					else
						-- dont make switch
						s_data(i) 		<= i_data(i);
						s_data(i + 1)		<= i_data(i + 1);
					end if;
				elsif ((i mod 2 = 1) AND (odd = '1')) then
					-- odd pass compare 1 with 2, 3 with 4 etc
					-- check if switch is required -- sorting by both Chip ID and column
					if (i = 63) then
						-- at max address, do not change end bits
						s_data(0) <= i_data(0);
						s_data(63) <= i_data(63);
					else
						if (to_integer(unsigned(i_data(i + 1)(23 downto 14))) < to_integer(unsigned(i_data(i + 2)(23 downto 14)))) then
							-- make switch
							s_data(i + 1) 		<= i_data(i + 2);
							s_data(i + 2) 		<= i_data(i + 1);
						else
							-- dont make switch
							s_data(i + 1) 		<= i_data(i + 1);
							s_data(i + 2)		<= i_data(i + 2);
						end if;
					end if;
				end if;
			end loop;
		end if;
		o_data <= s_data;
	end process;
end a;
