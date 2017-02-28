-- active_controller.vhd

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;	-- constants file
use work.sppif_package.all;			-- custom type definitions		

entity active_controller is
	port(	clk, rst, en		: IN	std_logic;

		-- from ram
		ct_addr			: OUT	std_logic_vector(8 downto 0);
		ct_data			: IN	std_logic_vector(COUNT_RAM_WORD_SIZE - 1 downto 0);

		-- from router
		rd_en			: OUT	std_logic;
		rd_addr			: OUT	std_logic_vector(RD_RAM_ADDR_SIZE - 1 downto 0);
		rd_data			: IN	std_logic_vector(RD_WORD_SIZE - 1 downto 0);

		-- to mep
		wr_en			: OUT 	std_logic;
		wr_addr 		: OUT 	std_logic_vector(WR_RAM_ADDR_SIZE - 1 downto 0);
		wr_data 		: OUT	std_logic_vector(WR_WORD_SIZE - 1 downto 0);

		-- to fifo
		fifo_en 		: OUT 	std_logic;
		fifo_data		: OUT 	std_logic_vector(6 downto 0);

		-- to bypass controller
		bypass_en 		: OUT 	std_logic);
end active_controller;

architecture a of active_controller is

	-- Changed from variables to signals

	-- TODO assign these
	signal bcid_addr			:	std_logic_vector(8 downto 0);
	signal bcid_size			:	std_logic_vector(7 downto 0);
	-- in process variables
	shared variable rd_state 		: 	integer;
	signal rd_data_store 			: 	datatrain_rd;
	shared variable rd_processor_num 	: 	integer range 0 to (DATA_PROCESSOR_COUNT - 1);
	signal rd_bcid_store			: 	std_logic_vector(8 downto 0);
	signal rd_size_store			: 	std_logic_vector(7 downto 0);

	-- for data formatting
	signal rd_construct_store 		: 	datatrain_rd;
	signal wr_destruct_store 		: 	datatrain_wr;
	shared variable rd_iteration 		: 	integer range 0 to 7;
	shared variable wr_iteration 		: 	integer range 0 to 7;
	
	-- out process variables
	shared variable wr_state 		: 	integer;
	shared variable wr_processor_num 	: 	integer range 0 to (DATA_PROCESSOR_COUNT - 1);
	signal wr_data_store 			: 	datatrain_wr;
	signal wr_bcid_store			: 	std_logic_vector(8 downto 0);
	signal wr_size_store			: 	std_logic_vector(7 downto 0);

	-- use the data processor types defined in eif_package to create signal arrays for the data processor array
	signal processor_ready			: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);
	signal processor_complete		: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);
	signal dp_rd_en				:	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);
	signal dp_rd_addr			: 	dp_addr_vector;
	signal dp_rd_data			: 	dp_rd_data_vector;
	signal dp_rd_size			: 	dp_size_vector;
	signal dp_wr_en				: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);
	signal dp_wr_addr			: 	dp_addr_vector;
	signal dp_wr_data			: 	dp_wr_data_vector;
	signal dp_wr_size			: 	dp_size_vector;

	component data_processor is
		port(	clk, rst		: IN	std_logic;

			processor_ready		: INOUT std_logic;
			processor_complete	: INOUT	std_logic;

			rd_en			: IN	std_logic;
			rd_addr			: IN	std_logic_vector(8 downto 0);
			rd_data			: IN	datatrain_rd;
			rd_size			: IN	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0);

			wr_en			: IN	std_logic;
			wr_addr			: OUT	std_logic_vector(8 downto 0);
			wr_data			: OUT	datatrain_wr;
			wr_size			: INOUT	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0));
	end component;

	--generate the required number of processors and map them to the corresponding signals
	begin gen_processor:
	for i in 0 to DATA_PROCESSOR_COUNT - 1 generate
		data_processorx : data_processor
		port map( clk, rst,

			processor_ready(i),
			processor_complete(i),

			dp_rd_en(i),
			dp_rd_addr(i),
			dp_rd_data(i),
			dp_rd_size(i),

			dp_wr_en(i),
			dp_wr_addr(i),
			dp_wr_data(i),
			dp_wr_size(i));
	end generate gen_processor;

-- working above here


	process(rst, clk, en)
	begin
		if (rst = '1' OR en = '0') then

			fifo_en 		<= '0';
			rd_en 			<= '0';
			wr_en 			<= '0';
			ct_addr 		<= X"000";

			rd_state 		:= 0;
			rd_processor_num 	:= 0;

			bypass_en 		<= '0';

			rd_iteration 		:= 0;

		elsif rising_edge(clk) then
			if rd_state = 0 then
				if (ct_data <= MAX_FLAG_SIZE) AND (ct_data /= X"000") then
					-- mark as processed
					fifo_data 	<= (others => '0');
					fifo_en 	<= '1';

					-- store addr and size
					rd_bcid_store 	<= bcid_addr;
					rd_size_store 	<= bcid_size;

					-- read data in
					rd_state 	:= 1;
					rd_iteration 	:= 0;
				else
					-- flag for bypass
					fifo_data 	<= ct_data;
					fifo_en 	<= '1';

					-- prep for next addr
					if bcid_addr = X"1FF" then
						bcid_addr 	<= X"000";
					else
						bcid_addr 	<= bcid_addr + 1;
					end if;
					
					if bcid_size = X"1FF" then
						bcid_size 	<= X"000";
					else
						bcid_size 	<= bcid_size + 1;
					end if;
				end if;
			elsif rd_state = 1 then
				-- 
				fifo_en 	<= '0';
				rd_iteration 	:= rd_iteration + 1;

				-- prep for next state
				if rd_iteration = to_integer(unsigned(ct_data))/RD_WORD_SIZE then
					rd_state 	 := 2;
					rd_processor_num := rd_processor_num + 1;
				end if;
			elsif rd_state = 2 then
				if processor_ready(rd_processor_num) = '0' then -- Check if processor is free
					-- processor not free, increment
					rd_processor_num := rd_processor_num + 1; -- This should never be needed
				else
					-- processor free; pass data to processor
					dp_rd_data(rd_processor_num) 		<= rd_data_store;
					dp_rd_addr(rd_processor_num) 		<= rd_bcid_store;
					dp_rd_size(rd_processor_num) 		<= rd_size_store;
					processor_ready(rd_processor_num) 	<= '0';

					-- prep for next addr
					if bcid_addr = X"1FF" then
						bcid_addr 	<= X"000";
					else
						bcid_addr 	<= bcid_addr + 1;
					end if;
					
					if bcid_addr = max_addr then
						rd_state 	:= 3; -- state with no logic
					else
						bcid_addr 	<= bcid_addr + 1;
						rd_state 	:= 0;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- continuous input assignment	
	rd_addr <= rd_bcid_store (4 downto 0) & std_logic_vector (to_unsigned(rd_iteration, RD_RAM_ADDR_SIZE - 5));
	process
	begin
		for i in 0 to 24 * to_integer(unsigned(ct_data)) / (RD_WORD_SIZE - 1) loop
			rd_data_store(to_integer(unsigned(ct_data)) * rd_iteration + i) <= "00000000" & rd_data(24 * (i + 1) - 1  downto 24 * i);
		end loop;
	end process;

	process(rst,clk) -- data out process
	begin
		if rst = '1' then
			wr_en 			<= '0';
			wr_processor_num 	:= 0;
		elsif rising_edge(clk) then
			if wr_state = 0 then -- look for finished processor
				if processor_complete(wr_processor_num) = '1' then
					-- collect from processor
					wr_data_store 				<= dp_wr_data(wr_processor_num);
					wr_size_store 				<= dp_wr_size(wr_processor_num);
					wr_bcid_store 				<= dp_wr_addr(wr_processor_num);

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
				if wr_iteration * 16 >= to_integer(unsigned(wr_size_store)) then
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
		if processor_ready = X"FFFFFFFF" AND rd_state = 3 then -- active control complete
			bypass_en <= '1';
		end if;
	end process;
end a;
