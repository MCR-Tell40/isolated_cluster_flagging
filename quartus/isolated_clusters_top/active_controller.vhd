-- active_controller.vhd

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.detector_constant_declaration.all;		-- constants file

entity active_controller is
	port(
		clk, rst, en	: IN	std_logic;

		-- count ram
		ram_bcid			: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0);
		ram_size			: IN	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);

		-- from router
		rd_en				: OUT	std_logic;
		rd_addr			: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0);
		rd_data			: IN	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);

		-- to mep
		wr_en				: IN 	std_logic;
		wr_addr 			: OUT 	std_logic_vector(BCID_WIDTH - 1 downto 0);
		wr_data 			: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);

		-- to fifo
		fifo_en 			: OUT 	std_logic;
		fifo_data		: OUT 	std_logic_vector(BCID_WIDTH - 1 downto 0);

		-- to bypass controller
		bypass_en 		: OUT 	std_logic;
		bypass_bcid		: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0)); -- pass BCIDs to bypass controller
end active_controller;

architecture control of active_controller is

	signal current_bcid				:	std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal current_processor		:	std_logic_vector(3 downto 0); -- 4 bits required to count to 16

	-- in pipes
	signal rd_data_store 			: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
	signal rd_bcid_store				: 	std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal rd_size_store				: 	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);

	-- out process pipes
	signal wr_data_store 			: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
	signal wr_bcid_store				: 	std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal wr_size_store				: 	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);

	-- data processor pipes
	signal processor_ready			: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);	-- processor is ready for next bcid
	signal dp_rd_bcid					: 	std_logic_vector(BCID_WIDTH - 1 downto 0);				-- next bcid
	signal dp_rd_en					:	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0);	-- read in next bcid
	signal dp_rd_data					: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);			-- data for next bcid
	signal dp_rd_size					: 	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);			-- size of data of next bcid
	-- ouput side
	signal processor_complete		: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0); 	-- processor has finished with current data
	signal dp_wr_en					: 	std_logic_vector(DATA_PROCESSOR_COUNT - 1 downto 0); 	-- write current data
	signal dp_wr_data					: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);			-- current data
	signal dp_wr_bcid					: 	std_logic_vector(BCID_WIDTH - 1 downto 0);				-- bcid of current data
	--signal dp_wr_size					: 	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);			-- size of current data -- don't need

	component data_processor is
		port(
			clk					: IN	std_logic;
			rst					: IN	std_logic;

			ready					: OUT 	std_logic;
			rd_en					: IN	std_logic;
			rd_bcid				: IN	std_logic_vector(BCID_WIDTH - 1 downto 0);
			rd_data				: IN	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
			rd_size				: IN	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);

			complete				: OUT	std_logic;
			wr_en					: IN	std_logic;
			wr_bcid				: OUT	std_logic_vector(BCID_WIDTH - 1  downto 0);
			wr_data				: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0)
			-- wr_size				: OUT	std_logic_vector(RAM_WORD_SIZE - 1 downto 0) -- don't need
		);
	end component;

	--generate the required number of processors and map them to the corresponding signals
	begin gen_processors:
	for i in 0 to DATA_PROCESSOR_COUNT - 1 generate
		data_processor_component : data_processor
		port map(
			clk,
			rst,

			processor_ready(i),
			dp_rd_en(i),
			dp_rd_bcid,
			dp_rd_data,
			dp_rd_size,

			processor_complete(i),
			dp_wr_en(i),
			dp_wr_bcid,
			dp_wr_data
			-- dp_wr_size -- don't need
		);
	end generate gen_processors;

	-- replace with an if statement within the process when possible
	bypass_bcid <= current_bcid; -- bypass controller can bypass this bcid as soon as bypass_en is set high if active controller runs out of clock cycles
	
	dp_rd_data <= rd_data;
	dp_rd_bcid <= rd_addr;
	dp_rd_size <= ram_size;
	
	process(rst, clk)
	begin
		if rst = '1' then
			current_bcid 		<= (others => '0'); -- reset bcid count
			current_processor 	<= (others => '0'); -- reset processor count
		elsif rising_edge(clk) then
			ram_bcid 	<= current_bcid; 	-- pass bcid to count ram
			rd_addr 		<= current_bcid;	-- pass bcid to router
			rd_en 		<= '1';
			-- now find a data processor to pass it to for processing
			if processor_ready(to_integer(unsigned(current_processor))) = '1' then
				dp_rd_en(to_integer(unsigned(current_processor))) <= '1';
				if current_processor = "1111" then
					-- at processor 0x0F; loop to first processor
					current_processor <= (others => '0');
				else
					-- increment processor number
					current_processor <= current_processor + 1;
				end if;
			end if;
			
			-- check all processors, pass only ONE per clock cycle as they share a bus
			if processor_complete(0) = '1' then
				-- pass 0 to fifo
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
				dp_wr_en(0) <= '1';
				fifo_en		<= '1';
				-- mark processor as ready to accept more data and reset processor complete
				processor_complete(0) 	<= '0';
				processor_ready(0)		<= '1';
				
			elsif processor_complete(1) = '1' then
				-- pass 1 to fifo
				dp_wr_en(1) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
				-- mark processor as ready to accept more data and reset processor complete
				processor_complete(0) 	<= '0';
				processor_ready(0)		<= '1';
			elsif processor_complete(2) = '1' then
				-- pass 2 to fifo
				processor_complete(2) <= '0';
				dp_wr_en(2) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(3) = '1' then
				-- pass 3 to fifo
				processor_complete(3) <= '0';
				dp_wr_en(3) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(4) = '1' then
				-- pass 4 to fifo
				processor_complete(4) <= '0';
				dp_wr_en(4) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(5) = '1' then
				-- pass 5 to fifo
				processor_complete(5) <= '0';
				dp_wr_en(5) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(6) = '1' then
				-- pass 6 to fifo
				processor_complete(6) <= '0';
				dp_wr_en(6) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(7) = '1' then
				-- pass 7 to fifo
				processor_complete(7) <= '0';
				dp_wr_en(7) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(8) = '1' then
				-- pass 8 to fifo
				processor_complete(8) <= '0';
				dp_wr_en(8) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(9) = '1' then
				-- pass 9 to fifo
				processor_complete(9) <= '0';
				dp_wr_en(9) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(10) = '1' then
				-- pass 10 to fifo
				processor_complete(10) <= '0';
				dp_wr_en(10) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(11) = '1' then
				-- pass 11 to fifo
				processor_complete(11) <= '0';
				dp_wr_en(11) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(12) = '1' then
				-- pass 12 to fifo
				processor_complete(12) <= '0';
				dp_wr_en(12) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(13) = '1' then
				-- pass 13 to fifo
				processor_complete(13) <= '0';
				dp_wr_en(13) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(14) = '1' then
				-- pass 14 to fifo
				processor_complete(14) <= '0';
				dp_wr_en(14) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			elsif processor_complete(15) = '1' then
				-- pass 15 to fifo
				processor_complete(15) <= '0';
				dp_wr_en(15) <= '1';
				wr_addr <= dp_wr_bcid;
				wr_data <= dp_wr_data;
			end if;
		end if;
	end process;
end control;
