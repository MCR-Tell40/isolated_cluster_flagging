-- active_controller.vhd

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;	-- constants file
use work.eif_package.all;			-- custom type definitions		

entity active_controller is
	port(	clk, rst, en		: IN	std_logic;

		-- from ram
		ct_addr			: INOUT	std_logic_vector(8 downto 0);
		ct_data			: IN	std_logic_vector(COUNT_RAM_WORD_SIZE - 1 downto 0);

		-- from router
		rd_en			: OUT	std_logic;
		rd_addr			: INOUT	std_logic_vector(RD_RAM_ADDR_SIZE - 1 downto 0);
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
	-- in process variables
	shared variable rd_state 		: 	integer;
	shared variable rd_data_store 		: 	datatrain;
	shared variable rd_processor_num 	: 	integer range 0 to (DATA_PROCESSOR_COUNT - 1);
	shared variable rd_bcid_store		: 	std_logic_vector(8 downto 0);
	shared variable rd_size_store		: 	std_logic_vector(7 downto 0);

	-- for data formatting
	shared variable rd_construct_store 	: 	datatrain_rd;
	shared variable wr_destruct_store 	: 	datatrain_wr;
	shared variable rd_iteration 		: 	integer range 0 to 7;
	shared variable wr_iteration 		: 	integer range 0 to 7;
	
	-- out process variables
	shared variable wr_state 		: 	integer;
	shared variable wr_processor_num 	: 	integer range 0 to (DATA_PROCESSOR_COUNT - 1);
	shared variable wr_data_store 		: 	datatrain;
	shared variable wr_bcid_store		: 	std_logic_vector(8 downto 0);
	shared variable wr_size_store		: 	std_logic_vector(7 downto 0);

	-- some data processor signals require custom types (some vectors of vectors)
	type dp_addr_vector	is array (DATA_PROCESSOR_COUNT - 1 downto 0)	of std_logic_vector(8 downto 0);
	type dp_rd_data_vector	is array (DATA_PROCESSOR_COUNT - 1 downto 0)	of datatrain_rd;
	type dp_wr_data_vector	is array (DATA_PROCESSOR_COUNT - 1 downto 0)	of datatrain_wr;
	type dp_size_vector	is array (DATA_PROCESSOR_COUNT - 1 downto 0)	of std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0);
	
	-- use the previously defined types to create signals for each of the generated data processors
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
			wr_addr			: IN	std_logic_vector(8 downto 0);
			wr_data			: IN	datatrain_wr;
			wr_size			: IN	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0));
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
					fifo_en 	<= '1';

					-- store addr and size
					rd_bcid_store 	:= ct_addr;
					rd_size_store 	:= ct_data;

					-- read data in
					rd_state 	:= 1;
					rd_iteration 	:= 0;
				else
					-- flag for bypass
					fifo_data 	<= ct_data;
					fifo_en 	<= '1';

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
					rd_processor_num := rd_processor_num + 1; -- This should never be needed, but just in case.
				else
					-- processor free; pass data to processor
					rd_data(rd_processor_num) 		<= rd_data_store;
					data_bcid_in(rd_processor_num) 		<= rd_bcid_store;
					rd_size(rd_processor_num) 		<= rd_size_store;
					processor_ready(rd_processor_num) 	<= '0';

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
end a;