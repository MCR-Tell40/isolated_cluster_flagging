-- Control entity for dataprocessing the BCID's below the sort threshord AND ahead of schedual
-- Author: Nicholas Mead
-- Date Created: 14 Apr 2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.isolation_flagging_package.all;
use work.detector_constant_declaration.all;

entity isolation_flagging is
port(
	-- standard
	clk, rst 	: IN 	std_logic;
	rd_addr 	: OUT 	std_logic_vector (RD_RAM_ADDR_SIZE - 1 downto 0);
	rd_en		: OUT 	std_logic;
	rd_data 	: INOUT	std_logic_vector (RD_WORD_SIZE - 1 downto 0);

	-- Train Size RAM interface ct=count
	ct_addr 	: OUT 	std_logic_vector (8 downto 0);
	ct_data 	: IN 	std_logic_vector (COUNT_RAM_WORD_SIZE - 1 downto 0);
	
	-- MEP Interface
	wr_addr 	: OUT 	std_logic_vector (WR_RAM_ADDR_SIZE - 1 downto 0);
	wr_en		: OUT 	std_logic;
	wr_data 	: OUT	std_logic_vector (WR_WORD_SIZE - 1 downto 0);

	-- Bypass Interface
	fifo_rd_en 	: OUT 	std_logic;
	fifo_data	: IN  	std_logic_vector (6 downto 0);
	fifo_empty  	: IN	std_logic
);

end isolation_flagging;

architecture a of isolation_flagging is
	
	shared variable clk_count 	: natural;
	
	signal inter_clk, inter_rst 	: std_logic;
	-- count ram pipes
	signal ct_addr_pipe 		: std_logic_vector (8 downto 0);
	signal ct_data_pipe 		: std_logic_vector (COUNT_RAM_WORD_SIZE - 1 downto 0);

	-- fifo pipes
	signal fifo_wr_en_pipe		: std_logic;
	signal fifo_rd_en_pipe		: std_logic;
	signal fifo_empty_pipe 		: std_logic;
	signal fifo_wr_data_pipe	: std_logic_vector (6 downto 0);
	signal fifo_rd_data_pipe 	: std_logic_vector (6 downto 0);

	-- active control pipes
	signal ac_en_pipe		: std_logic;
	signal ac_rd_addr_pipe		: std_logic_vector(RD_RAM_ADDR_SIZE - 1 downto 0);
	signal ac_wr_addr_pipe		: std_logic_vector(WR_RAM_ADDR_SIZE - 1 downto 0);
	signal ac_rd_data_pipe		: std_logic_vector(RD_WORD_SIZE - 1 downto 0);
	signal ac_wr_data_pipe		: std_logic_vector(WR_WORD_SIZE - 1 downto 0);
	signal ac_rd_en_pipe		: std_logic;
	signal ac_wr_en_pipe 		: std_logic;
	signal bypass_en_pipe 		: std_logic;

	-- Bypass control pipes
	signal by_rd_addr_pipe		: std_logic_vector ( RD_RAM_ADDR_SIZE-1 downto 0);
	signal by_wr_addr_pipe 		: std_logic_vector ( WR_RAM_ADDR_SIZE-1 downto 0);
	signal by_rd_data_pipe 		: std_logic_vector ( RD_WORD_SIZE - 1 downto 0);
	signal by_wr_data_pipe 		: std_logic_vector ( WR_WORD_SIZE - 1 downto 0);
	signal by_rd_en_pipe		: std_logic; 		
	signal by_wr_en_pipe 		: std_logic;

	component active_control is
	port(
		-- Common control signals
		clk 			: IN    std_logic; 
		rst			: IN    std_logic; 
		en 			: IN 	std_logic;

		-- Router Interface
		rd_addr 		: OUT 	std_logic_vector (RD_RAM_ADDR_SIZE - 1 downto 0);
		rd_en			: OUT 	std_logic;
		rd_data 		: IN 	std_logic_vector (RD_WORD_SIZE - 1 downto 0);
		
		-- Train Size RAM interface ct=count
		ct_addr 		: OUT 	std_logic_vector (8 downto 0);
		ct_data 		: IN 	std_logic_vector (COUNT_RAM_WORD_SIZE - 1 downto 0);

		-- MEP Interface
		wr_addr 		: OUT 	std_logic_vector (WR_RAM_ADDR_SIZE-1 downto 0);
		wr_en			: OUT 	std_logic;
		wr_data 		: OUT	std_logic_vector (WR_WORD_SIZE - 1 downto 0);

		-- Bypass Interace
		fifo_wr_en 		: OUT 	std_logic;
		fifo_data		: OUT 	std_logic_vector (6 downto 0);
		bypass_en 		: OUT 	std_logic
	);
	end component;

	component interface_fifo is
	generic(
		constant DATA_WIDTH  	: 	positive := 6;
		constant FIFO_DEPTH	: 	positive := 32
	);
		
	port(
		clk, rst		: IN  	std_logic;
		write_en		: IN  	std_logic;
		data_in			: IN  	std_logic_vector (DATA_WIDTH - 1 downto 0);
		read_en			: IN  	std_logic;
		data_out		: OUT 	std_logic_vector (DATA_WIDTH - 1 downto 0);
		empty			: OUT 	std_logic;
		full			: OUT 	std_logic
	);
	end component;

	component bypass_control is
	generic(
		ADDR_PER_RAM 		: 	integer := 32;
		MAX_RAM_ADDR_STORE 	: 	integer := 512;
		SPP_PER_ADDR 		: 	integer := 16
	);
	
	port(
		-- standard
		clk, rst, en 		: IN 	std_logic;

		-- Router Interface
		rd_addr 		: OUT 	std_logic_vector ( RD_RAM_ADDR_SIZE-1 downto 0);
		rd_en			: OUT 	std_logic;
		rd_data 		: IN 	std_logic_vector ( RD_WORD_SIZE - 1 downto 0);
			
		-- MEP Interface
		wr_addr 		: OUT 	std_logic_vector ( WR_RAM_ADDR_SIZE-1 downto 0);
		wr_en			: OUT 	std_logic;
		wr_data 		: OUT	std_logic_vector ( WR_WORD_SIZE - 1 downto 0);

		-- Bypass Interface
		fifo_rd_en 		: OUT 	std_logic;
		fifo_data		: IN  	std_logic_vector (6 downto 0);
		fifo_empty  		: IN 	std_logic 
	);
	end component;
begin
	active_control1 : active_control
	port map(
		clk       	=> inter_clk,
		rst       	=> inter_rst,
		en	  	=> ac_en_pipe,

	    	rd_addr 	=> ac_rd_addr_pipe,
		rd_en		=> ac_rd_en_pipe,
		rd_data 	=> ac_rd_data_pipe,

		-- Train Size RAM interface ct=count
		ct_addr 	=> ct_addr_pipe,
		ct_data 	=> ct_data_pipe,

		-- MEP Interface
		wr_addr 	=> ac_wr_addr_pipe,
		wr_en		=> ac_wr_en_pipe,
		wr_data 	=> ac_wr_data_pipe,

		-- Bypass Interace
		fifo_wr_en 	=> fifo_wr_en_pipe,
		fifo_data	=> fifo_wr_data_pipe,
		bypass_en 	=> bypass_en_pipe
	);

    	interface_fifo1 : interface_fifo
    	port map(
    		clk		=> inter_clk,
		rst		=> inter_rst,
		write_en	=> fifo_wr_en_pipe,
		data_in		=> fifo_wr_data_pipe,
		read_en		=> fifo_rd_en_pipe,
		data_out	=> fifo_rd_data_pipe,
		empty		=> fifo_empty_pipe
    	);
	
	bypass_control1 : bypass_control
    	port map(
	    	clk 		=> inter_clk,
	    	rst     	=> inter_rst,
	    	en 		=> bypass_en_pipe,

	    	rd_addr 	=> by_rd_addr_pipe,
		rd_en		=> by_rd_en_pipe,
		rd_data 	=> by_rd_data_pipe,

		-- MEP Interface
		wr_addr 	=> by_wr_addr_pipe,
		wr_en		=> by_wr_en_pipe,
		wr_data 	=> by_wr_data_pipe,

		-- Bypass Interace
		fifo_rd_en 	=> fifo_rd_en_pipe,
		fifo_data	=> fifo_rd_data_pipe,
		fifo_empty  	=> fifo_empty_pipe
    	);

	process(clk)
	begin
		if bypass_en_pipe = '1' then
			-- bypass
    			rd_addr <= by_rd_addr_pipe;
    			rd_data <= by_rd_data_pipe;
    			rd_en 	<= by_rd_en_pipe;
	
    			wr_addr <= by_wr_addr_pipe;
    			wr_data <= by_wr_data_pipe;
    			wr_en 	<= by_wr_en_pipe;
    		else 
			-- active control
    			rd_addr <= ac_rd_addr_pipe;
    			rd_data <= ac_rd_data_pipe;
    			rd_en 	<= ac_rd_en_pipe;

    			wr_addr <= ac_wr_addr_pipe;
    			wr_data <= ac_wr_data_pipe;
    			wr_en 	<= ac_wr_en_pipe;    	
		end if;
	end process;

	process(rst, clk)
	begin
	    	if rst = '1' then
    			clk_count 		:= 0;
    			ac_en_pipe 		<= '0';
    		elsif rising_edge(clk) then
	    		if clk_count < BUFFER_LIFETIME - 1 then
	    			ac_en_pipe 	<= '1';
	    			clk_count 	:= clk_count + 1;
	    		else
	    			ac_en_pipe 	<= '0';
	    			clk_count 	:= 0;
	    		end if;
	    	end if;
    	end process;
end a;