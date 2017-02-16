-- Control entity for dataprocessing the BCID's below the sort threshord AND ahead of schedule
-- Author: Nicholas Mead
-- Date Created: 26 Apr 2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all; -- seems this package is superfluous, was making unsigned() not work, may have been conflicting with other pckage
use ieee.std_logic_unsigned.all;
use work.isolation_flagging_package.all;
use work.detector_constant_declaration.all;

entity bypass_control is
generic(
	ADDR_PER_RAM 			: 	integer := 32;
	MAX_RAM_ADDR_STORE 		: 	integer := 512;
	SPP_PER_ADDR 			: 	integer := 16
);

port(
	-- standard
	clk, rst, en 			: IN	std_logic;
		
	-- Router Interface
	rd_addr 			: OUT 	std_logic_vector (RD_RAM_ADDR_SIZE - 1 downto 0);
	rd_en				: OUT 	std_logic;
	rd_data 			: IN 	std_logic_vector (RD_WORD_SIZE - 1 downto 0);
	
	-- MEP Interface
	wr_addr 			: OUT 	std_logic_vector (WR_RAM_ADDR_SIZE - 1 downto 0);
	wr_en				: OUT 	std_logic;
	wr_data 			: OUT	std_logic_vector (WR_WORD_SIZE - 1 downto 0);

	-- Bypass Interace
	fifo_rd_en 			: OUT 	std_logic;
	fifo_data			: IN  	std_logic_vector (6 downto 0);
	fifo_empty  			: IN 	std_logic
);
end bypass_control;

architecture a of bypass_control is
	signal bcid			: 	std_logic_vector (8 downto 0);
	signal inter_reg 		: 	std_logic_vector (WR_WORD_SIZE - 1 downto 0); --need const for this

	shared variable spp_count 	: 	integer;
	shared variable rd_iteration 	: 	integer range 0 to (RD_SPP_PER_BCID * RD_SPP_SIZE / RD_WORD_SIZE) - 1;
	shared variable wr_iteration 	: 	integer range 0 to (WR_SPP_PER_BCID * WR_SPP_SIZE / WR_WORD_SIZE) - 1;
	shared variable state 		: 	integer := 0;

begin
	rd_addr 	<= bcid(4 downto 0) & std_logic_vector(to_unsigned(rd_iteration, RD_RAM_ADDR_SIZE - 5));
	wr_addr 	<= bcid(4 downto 0) & std_logic_vector(to_unsigned(wr_iteration, WR_RAM_ADDR_SIZE - 5));

	process(clk, rst, en)
	begin
		if rst = '1' OR en = '0' then
			bcid 				<= (others => '0');
			--current_read_cycle		:= 0;
			state 				:= 0;

			rd_en 				<= '0';
			wr_en 				<= '0';
			fifo_rd_en 			<= '0';
		elsif rising_edge(clk) then
			if state = 0 then
				-- pre state 1
				fifo_rd_en 		<= '1';
				state 			:= 1;
			elsif state = 1 then
				spp_count 		:= to_integer(unsigned(fifo_data));

				wr_en 			<= '0'; -- for when state returns to 1 from 4

				if to_integer(unsigned(fifo_data)) > 0 then
					-- stop reading FIFO, start bypassing
					fifo_rd_en 	<= '0';
					rd_en 		<= '1';
					rd_iteration 	:= 0;
					state 		:= 2;
				else
					--re-do state for next bcid
					bcid <= bcid + "1";
				end if;
			elsif state = 2 then
				for i in 1 to 15 loop
					inter_reg(((i * 32) - 1 ) downto ((i - 1) * 32) ) <= "0X00" & rd_data(((i * 24) - 1) downto ((i - 1) * 24));
				end loop;

				if (rd_iteration + 1) * 8 >= spp_count then
					rd_en 		<= '0';
					state 		:= 4;
				else
					rd_iteration 	:= rd_iteration + 1;
					state 		:= 3;
				end if;
			elsif state = 3 then
				wr_en 			<= '1';
				wr_data 		<= inter_reg;
				wr_iteration 		:= rd_iteration - 1;

				for i in 1 to 15 loop
					inter_reg(((i * 32) - 1 ) downto ((i - 1) * 32) ) <= "0X00" & rd_data(((i * 24) - 1)  downto ((i - 1) * 24));
				end loop;

				if (rd_iteration + 1) * 8 >= spp_count then
					rd_en 		<= '0';
					state 		:= 4;
				else
					rd_iteration 	:= rd_iteration + 1;
					state 		:= 3;
				end if;

			elsif state = 4 then
				wr_en 			<= '1';
				wr_data 		<= inter_reg;
				wr_iteration 		:= rd_iteration;
	
				fifo_rd_en 		<= '1'; -- ready for state 1
				state 			:= 1;
			end if;
		end if;
	end process;
end a;

