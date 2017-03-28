-- Bubble Sorter
-- This entity takes a datatrain input and outputs the datatrain one bubblesort iteration later.
-- Even defined by parity of LSB
-- Output is in descending order, highest BCID at top -- this is so padding 0's in datatrain are all at the bottom
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 19/11/2015


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.detector_constant_declaration.all;	-- constants file

entity sorter is
	port(
		clk		: IN std_logic;
		rst        : IN	std_logic;
      	parity        	: IN	std_logic; -- high when odd
      	rd_data       	: IN	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
      	wr_data		: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0)
	);
end entity;

architecture a of sorter is
	signal inter_reg	: std_logic_vector(DATA_WORD_SIZE - 1 downto 0); -- intermediate shift register

begin

end a;
