-- Control entity for processing the BCIDs below the sort threshold and ahead of schedule
-- Author: Nicholas Mead
-- Date Created: 14 Apr 2016
-- Code not working

-- Edited by Dónal Murray

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.isolation_flagging_package.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;

entity active_control is 
port(
	-- standard
	clk, rst, en 	: 	IN 	std_logic;

	-- Router Interface
	rd_addr 	: 	INOUT 	std_logic_vector ( RD_RAM_ADDR_SIZE - 1 downto 0);
	rd_en		:	OUT 	std_logic;
	rd_data 	:	IN 	std_logic_vector ( RD_WORD_SIZE - 1  downto 0);

	-- Train Size RAM interface ct=count
	ct_addr 	: 	INOUT 	std_logic_vector ( 8 downto 0);
	ct_data 	:	IN 	std_logic_vector ((COUNT_RAM_WORD_SIZE - 1) downto 0);

	-- MEP Interface
	wr_addr 	: 	OUT 	std_logic_vector ((WR_RAM_ADDR_SIZE - 1) downto 0);
	wr_en		:	OUT 	std_logic;
	wr_data 	:	OUT	std_logic_vector ((WR_WORD_SIZE - 1) downto 0);

	-- Bypass Interace
	fifo_wr_en 	:	OUT 	std_logic;
	fifo_data  	:	OUT 	std_logic_vector (6 downto 0);
	bypass_en  	: 	OUT 	std_logic
);

end active_control;

architecture a of active_control is

	-- in process variables
	shared variable rd_state 		: integer;
	shared variable rd_data_store 		: datatrain;
	shared variable rd_processor_num 	: integer range 0 to (DATA_PROCESSOR_COUNT - 1);
	shared variable rd_bcid_store		: std_logic_vector (8 downto 0);
	shared variable rd_size_store		: std_logic_vector (7 downto 0);


	-- for data formatting
	shared variable rd_construct_store 	: datatrain_rd;
	shared variable wr_destruct_store 	: datatrain_wr;
	shared variable rd_iteration 		: integer range 0 to 7;
	shared variable wr_iteration 		: integer range 0 to 7;
	
	-- out process variables
	shared variable wr_state 		: integer;
	shared variable wr_processor_num 	: integer range 0 to (DATA_PROCESSOR_COUNT - 1);
	shared variable wr_data_store 		: datatrain;
	shared variable wr_bcid_store		: std_logic_vector (8 downto 0);
	shared variable wr_size_store		: std_logic_vector (7 downto 0);

	component data_processor is
	port(
		-- Common control signals
		rst			: IN    std_logic; -- rst
		clk 			: IN    std_logic; -- clk
		    	
		-- Data transfer	
		data_in     		: IN 	datatrain; -- data in
		data_out    		: OUT 	datatrain; -- data out
	
		data_size_in   		: IN    std_logic_vector ((DATA_SIZE_MAX_BIT - 1) downto 0);
		data_size_out 		: OUT   std_logic_vector ((DATA_SIZE_MAX_BIT - 1) downto 0);
		    
		-- Data processor active flag
		process_ready 		: INOUT std_logic;
		process_complete	: INOUT std_logic;

		-- BCID Address
		bcid_in        		: IN    std_logic_vector (8 downto 0); 
		bcid_out       		: OUT   std_logic_vector (8 downto 0)
	);
	end component;

	-- Data formatting components
	component split_datatrain is 
	port(
		data_in 		: IN 	datatrain;	-- 128 x 1 32-bit-SPP
		reset 			: IN 	std_logic;
		data_out		: OUT	datatrain_wr	-- 8 x 16 32-bit-SPP 
	);
	end component;

	component construct_datatrain is
	port(
		data_in 		: IN 	datatrain_rd;	-- 8 x 16 24-bit-SPP
		reset 			: IN 	std_logic;
		data_out		: OUT	datatrain	-- 128 x 1 32-bit-SPP
	);
	end component;

	signal processor_complete 	: std_logic_vector ((DATA_PROCESSOR_COUNT - 1) downto 0);
	signal processor_ready 		: std_logic_vector ((DATA_PROCESSOR_COUNT - 1) downto 0);
	
	begin
	gen_processors: for i in 0 to (DATA_PROCESSOR_COUNT - 1) generate
		begin
		processor_x : data_processor port map(
			rst,
			clk,
			    
			-- Data transfer
			processor_in(i),
			processor_out(i),
			    
			processor_size_in(i),
			processor_size_out(i),
		    
			-- Data processor active flag
			processor_ready(i),
			processor_complete(i),

			-- BCID Address
			processor_bcid_in(i),
			processor_bcid_out(i)
		);
	end generate gen_processors;

	process(rst, clk, en) -- data in process
	begin
		if (rst = '1' OR en = '0') then

			fifo_wr_en 		<= '0';
			rd_en 			<= '0';
			wr_en 			<= '0';
			ct_addr 		<= "0X000";

			rd_state 		:= 0;
			rd_processor_num 	:= 0;

			bypass_en 		<= '0';

			rd_iteration 		:= 0;

		elsif rising_edge(clk) then
			if rd_state = 0 then
				if (ct_data <= MAX_FLAG_SIZE) AND (ct_data /= "0X000") then
					-- mark as processed
					fifo_data 	<= (others => '0');
					fifo_wr_en 	<= '1';

					-- store addr and size
					rd_bcid_store 	:= ct_addr;
					rd_size_store 	<= ct_data;

					-- read data in
					rd_state 	:= 1;
					rd_iteration 	:= 0;
				else
					-- flag for bypass
					fifo_data 	<= ct_data;
					fifo_wr_en 	<= '1';

					-- prep for next addr
					if rd_addr = "0X1FF" then
						rd_addr 	<= "0X000";
					else
						rd_addr 	<= rd_addr + 1;
					end if;
					
					if ct_addr = "0X1FF" then
						ct_addr 	<= "0X000";
					else
						ct_addr 	<= ct_addr + 1;
					end if;
				end if;
			elsif rd_state = 1 then
				-- 
				fifo_wr_en 	<= '0';
				rd_iteration 	<= rd_iteration + 1;

				-- prep for next state
				if rd_iteration = to_integer(unsigned(ct_data))/RD_WORD_SIZE then
					rd_state 	 := 2;
					rd_processor_num := rd_processor_num + 1;
				end if;
			elsif rd_state = 2 then
				if processor_ready(rd_processor_num) = '0' then -- Check if processor is free
					-- processor not free, increment
					rd_processor_num 			:= rd_processor_num + 1; -- This should never be needed, but just in case.
				else
					-- processor free; pass data to processor
					processor_in (rd_processor_num) 	<= rd_data_store;
					processor_bcid_in (rd_processor_num) 	<= rd_bcid_store;
					processor_size_in (rd_processor_num) 	<= rd_size_store;
					processor_ready (rd_processor_num) 	<= '0';

					-- prep for next addr
					if rd_addr = "0X1FF" then
						rd_addr 	<= "0X000";
					else
						rd_addr 	<= rd_addr + 1;
					end if;
					
					if ct_addr = max_addr then
						rd_state 	:= 3; -- state with no logic
					else
						ct_addr 	<= ct_addr + 1;
						rd_state 	:= 0;
					end if;
				end if;
			end if;
		end if;
	end process;

	-- continious input assignment	
	rd_addr <= rd_bcid_store (4 downto 0) & std_logic_vector (to_unsigned(rd_iteration, RD_RAM_ADDR_SIZE - 5));
	process
	begin
		for i in 0 to 24 * to_integer(unsigned(ct_data)) / (RD_WORD_SIZE - 1) loop
			rd_data_store (to_integer(unsigned(ct_data)) * rd_iteration + i) <= "00000000" & rd_data(24 * (i + 1) - 1  downto 24 * i);
		end loop;
	end process;

	process(rst,clk) -- data out process
	begin
		if rst = '1' then
			wr_en 			<= '0';
			wr_processor_num 	:= 0;
		elsif rising_edge(clk) then
			if wr_state = 0 then -- look for finished processor
				if process_complete(wr_processor_num) = '1' then
					-- collect from processor
					wr_data_store 				:= processor_out(wr_processor_num);
					wr_size_store 				:= processor_size_out(wr_processor_num);
					wr_bcid_store 				:= processor_bcid_out(wr_processor_num);

					-- signal collection
					processor_complete(wr_processor_num) 	<= '0';

					-- next state prep
					wr_state 				:= 1;
					wr_en 					<= '1';
					wr_iteration 				:= 0;
				else
					-- check next processor
					wr_processor_num 			:= wr_processor_num + 1;
				end if;
			elsif wr_state = 1 then -- read out 
				-- check if last iteration
				if wr_iteration*16 >= to_integer(unsigned(wr_size_store)) then
					wr_state 	:= 0;
					wr_en 		<= '0';
				else
					wr_iteration 	:= wr_iteration + 1;
				end if;
			end if;
		end if;
	end process;
	
	-- continuous output assignment	
	wr_addr <= wr_bcid_store(4 downto 0) & std_logic_vector(to_unsigned(wr_iteration, WR_RAM_ADDR_SIZE - 5));
	wr_data <= wr_data_store(wr_iteration);

	process
	begin
		if processor_ready = '0XFFFFFFFF' AND rd_state = 3 then -- active control complete
			bypass_en <= '1';
		end if;
	end process;
end a;