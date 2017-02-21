-- counter.vhd
-- counting unit

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;	-- constants file

entity counter is
port(
	clk, rst, en		: IN 	std_logic;
	count 			: OUT	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0)
);
end entity;

architecture a of counter is
	-- intermediate shift register
	signal inter_reg	: 	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0);
begin
	process(clk, rst, en)
	begin
		if (rst = '1') then
			inter_reg	<= x"00";
		elsif (rising_edge(clk) AND en = '1') then
			if (inter_reg = x"FF") then
				inter_reg 	<= x"00";
			else
				inter_reg 	<= inter_reg + 1;
			end if;
		end if;
	end process;
	count	<= inter_reg;
end a;
