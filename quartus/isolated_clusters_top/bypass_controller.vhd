--bypass_controller.vhd
-- passes SPPs along which are marked for bypass by active controller


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;	-- constants file

entity bypass_controller is
	port(
		clk 			: IN 	std_logic;
		rst 			: IN 	std_logic;
		en 				: IN 	std_logic;
		-- router
		rd_en			: OUT 	std_logic;
		rd_addr 		: IN 	std_logic_vector(BCID_WIDTH - 1 downto 0);
		rd_data 		: IN 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
		-- mep
		wr_en			: OUT 	std_logic;
		wr_addr 		: OUT 	std_logic_vector(BCID_WIDTH - 1 downto 0);
		wr_data 		: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
		-- fifo
		fifo_rd_en 		: OUT 	std_logic;
		fifo_data		: IN  	std_logic_vector(BCID_WIDTH - 1 downto 0);
		fifo_empty  	: IN 	std_logic
	);
end bypass_controller;

architecture bypass of bypass_controller is
	signal bcid			: 	std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal inter_reg 	: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
	begin
end bypass;
