--eif_top.vhd
-- Top level block for EIF module
-- Event isolation flagging (EIF) module aims to find SPPs with no adjacent SPPs and flag them in the FPGA to reduce load on CPU


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;	-- constants file
use work.eif_package.all;			-- custom type definitions

entity eif_top is
port(
	clk, rst	: IN	std_logic;

	ct_addr		: OUT	std_logic_vector(8 downto 0);				-- number of addresses
	ct_data		: IN	std_logic_vector(COUNT_RAM_WORD_SIZE - 1 downto 0);	-- number of 

	rd_en		: OUT	std_logic;						-- read enable
	rd_addr		: OUT	std_logic_vector(RD_RAM_ADDR_SIZE - 1 downto 0);	-- addresses of all SPPs to be input
	rd_data		: INOUT	std_logic_vector(RD_WORD_SIZE - 1 downto 0);		-- SPP data input

	wr_en		: OUT	std_logic;						-- write enable
	wr_addr		: OUT	std_logic_vector(WR_RAM_ADDR_SIZE - 1 downto 0);	-- addresses of SPPs to be output
	wr_data		: OUT	std_logic_vector(WR_WORD_SIZE - 1 downto 0);		-- SPP data input
);
end eif_top;
