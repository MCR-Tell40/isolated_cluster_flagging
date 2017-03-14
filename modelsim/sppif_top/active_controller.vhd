-- active_controller.vhd

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;	-- constants file
use work.sppif_package.all;			-- custom type definitions		

entity active_controller is
	port(	clk, rst, en		: IN	std_logic;

		-- from count ram
		ram_bcid		: OUT	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
		ram_size		: IN	std_logic_vector(COUNT_RAM_WORD_SIZE - 1 downto 0);

		-- from router
		rd_en			: OUT	std_logic;
		rd_addr			: OUT	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
		rd_data			: IN	std_logic_vector(RD_WORD_SIZE - 1 downto 0);

		-- to mep
		wr_en			: OUT 	std_logic;
		wr_addr 		: OUT 	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
		wr_data 		: OUT	std_logic_vector(WR_WORD_SIZE - 1 downto 0);

		-- to fifo
		fifo_en 		: OUT 	std_logic;
		fifo_data		: OUT 	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);

		-- to bypass controller
		bypass_en 		: OUT 	std_logic;
		bcid_in			: IN	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0)); -- take current BCID from bypass controller
end active_controller;

architecture a of active_controller is
	
	signal current_bcid			:	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);

	-- in pipes
	signal rd_data_store 			: 	datatrain_rd;
	signal rd_bcid_store			: 	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	signal rd_size_store			: 	std_logic_vector(7 downto 0);
	
	-- out process pipes
	signal wr_data_store 			: 	datatrain_wr;
	signal wr_bcid_store			: 	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	signal wr_size_store			: 	std_logic_vector(7 downto 0);

	-- use the data processor types defined in sppif_package to create signal arrays for the data processor array
	signal processor_ready			: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);
	signal processor_complete		: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);
	signal dp_rd_en				:	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);
	signal dp_rd_bcid			: 	dp_bcid_vector;
	signal dp_rd_data			: 	dp_rd_data_vector;
	signal dp_rd_size			: 	dp_size_vector;
	signal dp_wr_en				: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);
	signal dp_wr_bcid			: 	dp_bcid_vector;
	signal dp_wr_data			: 	dp_wr_data_vector;
	signal dp_wr_size			: 	dp_size_vector;

	-- unavoidable shared variables (only required to be shared because of the two assignment processes
	-- not a good idea as behaviour is undefine for concurrent writes to the same variable by different processes
	-- read process variables
	--shared variable rd_state 		: 	natural;
	--shared variable rd_iteration		: 	natural range 0 to 7;
	-- write process variables
	--shared variable wr_iteration 		: 	natural range 0 to 7;

	component data_processor is
		port(	clk, rst		: IN	std_logic;

			processor_ready		: INOUT std_logic;
			processor_complete	: INOUT	std_logic;

			rd_en			: IN	std_logic;
			rd_bcid			: IN	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
			rd_data			: IN	datatrain_rd;
			rd_size			: IN	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0);

			wr_en			: IN	std_logic;
			wr_bcid			: OUT	std_logic_vector(SPP_BCID_WIDTH - 1  downto 0);
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
			dp_rd_bcid(i),
			dp_rd_data(i),
			dp_rd_size(i),

			dp_wr_en(i),
			dp_wr_bcid(i),
			dp_wr_data(i),
			dp_wr_size(i));
	end generate gen_processor;


	--rd_addr <= rd_bcid_store (4 downto 0) & std_logic_vector (to_unsigned(rd_iteration, SPP_BCID_WIDTH - 5));
--	wr_addr <= wr_bcid_store(4 downto 0) & std_logic_vector(to_unsigned(wr_iteration, SPP_BCID_WIDTH - 5));
--	wr_data <= wr_data_store(wr_iteration);

--	-- input assignment	
--	process(rd_data_store)
--	begin
--		for i in 0 to RD_SPP_SIZE * to_integer(unsigned(ram_size)) / (RD_WORD_SIZE - 1) loop
--			rd_data_store(to_integer(unsigned(ram_size)) * rd_iteration + i) <= "00000000" & rd_data(RD_SPP_SIZE * (i + 1) - 1  downto RD_SPP_SIZE * i);
--		end loop;
--	end process;
--	-- output assignment	
--	process(processor_ready)
--	begin
--		if processor_ready = X"FFFFFFFF" AND rd_state = 3 then -- active control complete
--			bypass_en <= '1';
--		end if;
--	end process;

	process(rst, clk, en, rd_bcid_store)
		variable rd_processor_num	:	natural range 0 to (DATA_PROCESSOR_COUNT - 1);
		variable rd_state 		: 	natural;
		variable rd_iteration		: 	natural; --range 0 to 7;
	begin

		rd_addr <= rd_bcid_store (4 downto 0) & std_logic_vector (to_unsigned(rd_iteration, SPP_BCID_WIDTH - 5));

		--for i in 0 to RD_SPP_SIZE * to_integer(unsigned(ram_size)) / (RD_WORD_SIZE - 1) loop
--			rd_data_store(to_integer(unsigned(ram_size)) * rd_iteration + i) <= "00000000" & rd_data(RD_SPP_SIZE * (i + 1) - 1  downto RD_SPP_SIZE * i);
--		end loop;

		if (rst = '1' OR en = '0') then

			fifo_en 		<= '0';
			rd_en 			<= '0';
			wr_en 			<= '0';
			ram_bcid 		<= (others => '0');	-- was wrong size: ram_bcid length 9; X"000" length 12 - should be 9 bits (BCID)

			rd_state 		:= 0;
			rd_processor_num 	:= 0;

			bypass_en 		<= '0';

			rd_iteration 		:= 0;

		elsif rising_edge(clk) then
			if rd_state = 0 then
				if (ram_size <= MAX_ADDR) AND (ram_size /= X"000000000") then
					-- mark as processed
					fifo_data 	<= (others => '0');
					fifo_en 	<= '1';

					-- store addr and size
					rd_bcid_store 	<= bcid_in;
					rd_size_store 	<= ram_size;

					-- read data in
					rd_state 	:= 1;
					rd_iteration 	:= 0;
				else
					-- flag for bypass
					fifo_data 	<= bcid_in;	-- pass bcid to fifo
					fifo_en 	<= '1';

					-- reset if at end
					if bcid_in = X"1FF" then
						rd_addr 	<= (others => '0');
						ram_bcid 	<= (others => '0');
					else
						rd_addr 	<= bcid_in + 1;
						ram_bcid 	<= bcid_in + 1;
					end if;
				end if;
			elsif rd_state = 1 then
				-- 
				fifo_en 	<= '0';
				rd_iteration 	:= rd_iteration + 1;

				-- prep for next state
				if rd_iteration = to_integer(unsigned(bcid_in))/RD_WORD_SIZE then
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
					dp_rd_bcid(rd_processor_num) 		<= rd_bcid_store;
					dp_rd_size(rd_processor_num) 		<= rd_size_store;
					processor_ready(rd_processor_num) 	<= '0';

					-- prep for next addr
					if bcid_in = X"1FF" then
						-- at the end, reset to the first bcid
						rd_addr 	<= (others => '0');	-- was wrong size: rd_bcid length 9; X"000" length 12
					else
						rd_addr 	<= bcid_in + 1;
					end if;
					
					if bcid_in = MAX_ADDR then
						rd_state	:= 3; -- state with no logic
					else
						rd_addr 	<= bcid_in + 1;
						rd_state 	:= 0;
					end if;
				end if;
			end if;
		end if;

		if processor_ready = X"FFFFFFFF" AND rd_state = 3 then -- active control complete
			bypass_en <= '1';
		end if;
	end process;
	
	process(rst, clk, wr_bcid_store) -- data out process
		variable wr_state 		: 	natural;
		variable wr_processor_num 	: 	natural range 0 to (DATA_PROCESSOR_COUNT - 1);
		variable wr_iteration 		: 	natural range 0 to 7;
	begin
		-- output assignment
		wr_addr <= wr_bcid_store(4 downto 0) & std_logic_vector(to_unsigned(wr_iteration, SPP_BCID_WIDTH - 5));
		wr_data <= wr_data_store(wr_iteration);

		if rst = '1' then
			wr_en 			<= '0';
			wr_processor_num 	:= 0;
		elsif rising_edge(clk) then
			if wr_state = 0 then -- look for finished processor
				if processor_complete(wr_processor_num) = '1' then
					-- collect from processor
					wr_data_store 				<= dp_wr_data(wr_processor_num);
					wr_size_store 				<= dp_wr_size(wr_processor_num);
					wr_bcid_store 				<= dp_wr_bcid(wr_processor_num);

					-- signal collection
					processor_complete(wr_processor_num) 	<= '0';

					-- next state prep
					wr_state 				:= 1;
					wr_en 					<= '1';
					wr_iteration 				:= 0;
				else
					-- check next processor
					if wr_processor_num = DATA_PROCESSOR_COUNT - 1 then
						-- at last processor, go to first
						wr_processor_num			:= 0;
					else
						-- go to next processor
						wr_processor_num 			:= wr_processor_num + 1;
					end if;
				end if;
			elsif wr_state = 1 then -- read out 
				-- check if last iteration
				if wr_iteration * SPP_PER_BCID >= to_integer(unsigned(wr_size_store)) then
					wr_state 	:= 0;
					wr_en 		<= '0';
				else
					wr_iteration 	:= wr_iteration + 1;
				end if;
			end if;
		end if;
	end process;
end a;
