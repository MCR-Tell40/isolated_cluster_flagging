--eif_top.vhd
-- Top level block for EIF module
-- Event isolation flagging (EIF) module aims to find SPPs with no adjacent SPPs and flag them in the FPGA to reduce load on CPU


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;	-- constants file
use work.sppif_package.all;			-- custom type definitions

entity sppif_top is
	port(	clk, rst	: IN	std_logic;

		-- train size ram interface
		ram_bcid	: OUT	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);		-- current bcid
		ram_size	: IN	std_logic_vector(COUNT_RAM_WORD_SIZE - 1 downto 0);	-- number of spps in this bcid's ram

		-- from ram
		rd_en		: OUT	std_logic;						-- read enable
		rd_addr		: OUT	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);		-- bcid of SPPs to be input
		rd_data		: IN	std_logic_vector(RD_WORD_SIZE - 1 downto 0);		-- SPP data input

		-- to output
		wr_en		: OUT	std_logic;						-- write enable
		wr_addr		: OUT	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);		-- addresses of SPPs to be output
		wr_data		: OUT	std_logic_vector(WR_WORD_SIZE - 1 downto 0));		-- SPP data output
end sppif_top;

architecture a of sppif_top is
-- internal signal pipes
	-- active controller pipes
	signal ac_en_pipe		: std_logic;
	-- count ram
	signal ram_bcid_pipe		: std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	signal ram_size_pipe		: std_logic_vector(COUNT_RAM_WORD_SIZE - 1 downto 0);
	-- router
	signal ac_rd_en_pipe		: std_logic;
	signal ac_rd_addr_pipe		: std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	signal ac_rd_data_pipe		: std_logic_vector(RD_WORD_SIZE - 1 downto 0);
	-- mep
	signal ac_wr_en_pipe 		: std_logic;
	signal ac_wr_addr_pipe		: std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	signal ac_wr_data_pipe		: std_logic_vector(WR_WORD_SIZE - 1 downto 0);

	-- fifo pipes
	-- active controller
	signal fifo_wr_en_pipe		: std_logic;
	signal fifo_wr_data_pipe	: std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	-- bypass controller
	signal fifo_rd_en_pipe		: std_logic;
	signal fifo_rd_data_pipe 	: std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	signal fifo_empty_pipe 		: std_logic;

	-- bypass controller pipes
	-- active controller
	signal by_en_pipe 		: std_logic;
	-- router
	signal by_rd_en_pipe		: std_logic; 
	signal by_rd_addr_pipe		: std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	signal by_rd_data_pipe 		: std_logic_vector(RD_WORD_SIZE - 1 downto 0);
	-- mep
	signal by_wr_en_pipe 		: std_logic;
	signal by_wr_addr_pipe 		: std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
	signal by_wr_data_pipe 		: std_logic_vector(WR_WORD_SIZE - 1 downto 0);


-- define components
	component active_controller is
		port(	clk, rst, en		: IN	std_logic;

			-- from ram
			ram_bcid		: OUT	std_logic_vector(8 downto 0);
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
			bcid_in			: IN	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0)); -- take current BCID from bypass controller);
	end component;

	component interface_fifo is
		port(	clk, rst		: IN	std_logic;
			empty, full		: OUT 	std_logic;

			-- from active controller
			wr_en			: IN  	std_logic;
			wr_data			: IN  	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);

			-- to bypass controller
			rd_en			: IN  	std_logic;
			rd_data			: OUT 	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0));
	end component;

	component bypass_controller is
		port(	clk, rst, en 		: IN 	std_logic;
	
			-- from router
			rd_en			: OUT 	std_logic;
			rd_addr 		: OUT 	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
			rd_data 		: IN 	std_logic_vector(RD_WORD_SIZE - 1 downto 0);
				
			-- to mep
			wr_en			: OUT 	std_logic;
			wr_addr 		: OUT 	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
			wr_data 		: OUT	std_logic_vector(WR_WORD_SIZE - 1 downto 0);
	
			-- from fifo
			fifo_rd_en 		: OUT 	std_logic;
			fifo_data		: IN  	std_logic_vector(SPP_BCID_WIDTH - 1 downto 0);
			fifo_empty  		: IN 	std_logic);
	end component;

	begin

	-- generate components
	active_controller1 : active_controller
	port map( clk		=> clk,
		rst		=> rst,
		en		=> ac_en_pipe,

		-- from ram
		ram_bcid	=> ram_bcid_pipe,
		ram_size	=> ram_size_pipe,

		-- from router
		rd_en		=> ac_rd_en_pipe,
		rd_addr		=> ac_rd_addr_pipe,
		rd_data		=> ac_rd_data_pipe,

		-- to mep
		wr_en		=> ac_wr_en_pipe,
		wr_addr		=> ac_wr_addr_pipe,
		wr_data		=> ac_wr_data_pipe,

		-- to fifo
		fifo_en		=> fifo_wr_en_pipe,
		fifo_data	=> fifo_wr_data_pipe,

		-- to bypass controller
		bypass_en	=> by_en_pipe,
		bcid_in		=> by_rd_addr_pipe);

	interface_fifo1 : interface_fifo
	port map( clk		=> clk,
		rst		=> rst,
		empty		=> fifo_empty_pipe,

		-- from active controller
		wr_en		=> fifo_wr_en_pipe,
		wr_data		=> fifo_wr_data_pipe,

		-- to bypass controller
		rd_en		=> fifo_rd_en_pipe,
		rd_data		=> fifo_rd_data_pipe);
	
	bypass_controller1 : bypass_controller
    	port map( clk 		=> clk,
	    	rst     	=> rst,
	    	en 		=> by_en_pipe,

		-- from router
		rd_en		=> by_rd_en_pipe,
	    	rd_addr 	=> by_rd_addr_pipe,
		rd_data 	=> by_rd_data_pipe,

		-- to mep
		wr_en		=> by_wr_en_pipe,
		wr_addr 	=> by_wr_addr_pipe,
		wr_data 	=> by_wr_data_pipe,

		-- from fifo
		fifo_rd_en 	=> fifo_rd_en_pipe,
		fifo_data	=> fifo_rd_data_pipe,
		fifo_empty  	=> fifo_empty_pipe);

-- processes
	ram_bcid <= ram_bcid_pipe;
	ram_size_pipe <= ram_size;

	process(clk)
	begin
		if by_en_pipe = '1' then
			-- bypass this block
			rd_addr 	<= by_rd_addr_pipe;
    			by_rd_data_pipe <= rd_data;
    			rd_en 		<= by_rd_en_pipe;
	
    			wr_addr 	<= by_wr_addr_pipe;
    			wr_data 	<= by_wr_data_pipe;
    			wr_en 		<= by_wr_en_pipe;
    		else 
			-- pass to active control
    			rd_addr 	<= ac_rd_addr_pipe;
    			ac_rd_data_pipe <= rd_data;
    			rd_en 		<= ac_rd_en_pipe;

    			wr_addr 	<= ac_wr_addr_pipe;
    			wr_data 	<= ac_wr_data_pipe;
    			wr_en 		<= ac_wr_en_pipe;    	
		end if;
	end process;

	process(rst, clk)
		variable clk_count	: natural;	-- to keep track of number of clock cycles
	begin
	    	if rst = '1' then
			-- reset the system
    			clk_count 	:= 0;	-- reset clock cycle count
    			ac_en_pipe 	<= '0';	-- disable active controller
    		elsif rising_edge(clk) then
	    		if clk_count < BUFFER_LIFETIME - 1 then
				-- within buffer lifetime
	    			ac_en_pipe 	<= '1';			-- enable active controller
	    			clk_count 	:= clk_count + 1;	-- increment clock cycle count
	    		else
				-- reset the system
    				ac_en_pipe 	<= '0';			-- disable active controller
    				clk_count 	:= 0;			-- reset clock cycle count
	    		end if;
	    	end if;
    	end process;
end a;
