-- isolated_clusters_top:		Top level for drop-in isolated clusters module
-- 	The isolated clusters module sorts the columns and checks for hits with
-- 	no neighbours. Then the isolated columns  are flagged for bypass.
--	Doing this in the hardware stage (in the FPGA) decreases the load on the
--	CPU in the software stage

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.detector_constant_declaration.all;

entity isolated_clusters_top is
	port(
		clk			: IN	std_logic;										-- clock
		rst			: IN	std_logic;										-- reset
		-- count ram interface
		ram_bcid	: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0);		--
		ram_size	: IN	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);	--
		-- input
		rd_en		: OUT	std_logic;										-- read enable
		rd_addr		: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0);		-- bcid of SPPs to be input
		rd_data		: IN	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);	-- SPP data input
		-- output
		wr_en		: IN	std_logic;										-- write enable
		wr_addr		: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0);		-- bcid to be written
		wr_data		: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0)	-- write data
	);
end isolated_clusters_top;

architecture top_level of isolated_clusters_top is
	-- signal declaration
	-- active controller
	signal ac_en			: 		std_logic;
	signal ac_rd_en			: 		std_logic;
	signal ac_rd_addr		: 		std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal ac_rd_data		: 		std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
	signal ac_wr_en			: 		std_logic;
	signal ac_wr_addr		: 		std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal ac_wr_data		: 		std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
	-- fifo
	signal fifo_wr_en		: 		std_logic;
	signal fifo_wr_data		: 		std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal fifo_rd_en		: 		std_logic;
	signal fifo_rd_data		: 		std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal fifo_empty		: 		std_logic;
	-- bypass controller
	signal by_en			: 		std_logic;
	signal by_rd_en		:		std_logic;
	signal by_rd_addr		: 		std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal by_rd_data		: 		std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
	signal by_wr_en		:		std_logic;
	signal by_wr_addr		: 		std_logic_vector(BCID_WIDTH - 1 downto 0);
	signal by_wr_data		: 		std_logic_vector(DATA_WORD_SIZE - 1 downto 0);

	-- define components
	component active_controller is
		port(
			clk				: IN	std_logic;
			rst				: IN	std_logic; -- 1 to reset
			en				: IN	std_logic; -- 1 is enabled
			-- count ram
			ram_bcid		: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0);
			ram_size		: IN	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);
			-- router
			rd_en			: OUT	std_logic;
			rd_addr			: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0);
			rd_data			: IN	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
			-- MEP
			wr_en			: IN 	std_logic;
			wr_addr 		: OUT 	std_logic_vector(BCID_WIDTH - 1 downto 0);
			wr_data 		: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
			-- fifo
			fifo_en 		: OUT 	std_logic;
			fifo_data		: OUT 	std_logic_vector(BCID_WIDTH - 1 downto 0);
			-- bypass controller
			bypass_en 		: OUT 	std_logic;
			bypass_bcid			: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0)
		);
	end component;

	component mep_fifo is
		port(
			clk				: IN	std_logic;
			rst				: IN	std_logic; -- 1 to reset
			empty			: OUT	std_logic; -- 1 empty, 0 full
			-- active controller
			wr_en			: IN  	std_logic;
			wr_data			: OUT  	std_logic_vector(BCID_WIDTH - 1 downto 0);
			-- bypass controller
			rd_en			: IN  	std_logic;
			rd_data			: IN 	std_logic_vector(BCID_WIDTH - 1 downto 0)
		);
	end component;

	component bypass_controller is
		port(
			clk				: IN 	std_logic;
			rst				: IN 	std_logic; -- 1 to reset
			en 				: IN 	std_logic; -- 1 is enabled
			-- router
			rd_en			: OUT 	std_logic;
			rd_addr 		: IN 	std_logic_vector(BCID_WIDTH - 1 downto 0);
			rd_data 		: IN 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
			-- MEP
			wr_en			: OUT 	std_logic;
			wr_addr 		: OUT 	std_logic_vector(BCID_WIDTH - 1 downto 0);
			wr_data 		: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
			-- fifo
			fifo_rd_en 		: OUT 	std_logic;
			fifo_data		: IN  	std_logic_vector(BCID_WIDTH - 1 downto 0);
			fifo_empty  	: IN 	std_logic
		);
	end component;

	begin
	-- generate components
	active_controller_component : active_controller
	port map(
		clk			=> clk,
		rst			=> rst,
		en			=> ac_en,
		-- count ram
		ram_bcid	=> ram_bcid,
		ram_size	=> ram_size,
		-- router
		rd_en		=> ac_rd_en,
		rd_addr		=> ac_rd_addr,
		rd_data		=> ac_rd_data,
		-- MEP
		wr_en		=> ac_wr_en,
		wr_addr		=> ac_wr_addr,
		wr_data		=> ac_wr_data,
		-- fifo
		fifo_en		=> fifo_wr_en,
		fifo_data	=> fifo_wr_data,
		-- bypass controller
		bypass_en	=> by_en,
		bypass_bcid		=> by_rd_addr
	);

	interface_fifo_component : mep_fifo
	port map(
		clk			=> clk,
		rst			=> rst,
		empty		=> fifo_empty,
		-- bypass controller
		wr_en			=> fifo_wr_en,
		wr_data		=> fifo_wr_data,
		-- active controller
		rd_en		=> fifo_rd_en,
		rd_data		=> fifo_rd_data
	);

	bypass_controller_component : bypass_controller
    	port map(
			clk 		=> clk,
	    	rst     	=> rst,
	    	en 			=> by_en,
			-- router
			rd_en		=> by_rd_en,
	    	rd_addr 	=> by_rd_addr,
			rd_data 	=> by_rd_data,
			-- MEP
			wr_en		=> by_wr_en,
			wr_addr 	=> by_wr_addr,
			wr_data 	=> by_wr_data,
			-- fifo
			fifo_rd_en 	=> fifo_rd_en,
			fifo_data	=> fifo_wr_data,
			fifo_empty  => fifo_empty
	);

	-- active controller
	--input
	rd_en <= ac_rd_en;
	rd_addr <= ac_rd_addr;
	ac_rd_data <= rd_data;
	-- output
	ac_wr_en <= wr_en;
	wr_data <= ac_wr_data;

	-- bypass controller
	--by_rd_data <= rd_data;
	--rd_en <= by_rd_en;
	--wr_data <= by_wr_data;

end top_level;
