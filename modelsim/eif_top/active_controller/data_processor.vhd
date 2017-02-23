-- Bubble Sort
-- Even/Odd defined by parity of LSB
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 19/11/2015

-- 7 state process:
	-- state 0 = waiting for data
	-- state 1 = constructing datatrain
	-- state 2 = sorting data
	-- state 3 = flagging data
	-- state 4 = destructing datatrain
	-- state 5 = outputing sorted and flagged data
	-- state 6 = waiting for data to be read out


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.detector_constant_declaration.all;	-- constants file
use work.eif_package.all;			-- custom type definitions		


entity data_processor is
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
		wr_size			: OUT	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0));
end data_processor;

architecture a of data_processor is
-- define components
	component construct_datatrain is
	-- takes the zero-stripped output from the router and pads it with zeroes to create a datatrain
	port(	rst 			: IN 	std_logic;
		rd_data			: IN 	datatrain_rd;	-- 8 x 16 24-bit-SPP
		wr_data			: OUT	datatrain);	-- 128 x 1 32-bit-SPP
	end component;

	component split_datatrain is
	-- splits the datatrain into its constituent SPPs
	port(	rst 			: IN 	std_logic;
		rd_data 		: IN 	datatrain;	-- 128 x 1 32-bit-SPP
		wr_data			: OUT	datatrain_wr);	-- 8 x 16 32-bit-SPP
	end component;

	component sorter is
	-- implementation of the bubble sorting algorithm
    	port(	clk, rst        	: IN	std_logic; 
      		parity        		: IN	std_logic; -- high when odd
      		rd_data       		: IN	datatrain;
      		wr_data      		: OUT	datatrain);
	end component;

	component counter is
	-- 8 bit counter to keep track of how many clock cycles each SPP is processed for
    	port(	clk, rst, en		: IN 	std_logic;
    		count 			: OUT	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0));
  	end component;

  	component flagger is
	-- flags SPPs for bypass
    	port(	clk, rst       		: IN  	std_logic;
      		rd_data   		: IN  	datatrain;
      		wr_data  		: OUT 	datatrain);
  	end component;

-- variables
  	shared variable state 		: 	integer range 0 to 4;
-- signals
  	signal inter_reg   		: 	datatrain;
  	signal inter_size  		: 	std_logic_vector((DATA_SIZE_MAX_BIT - 1) downto 0); 	
  	signal bcid_addr 		: 	std_logic_vector(8 downto 0);
	-- construct datatrain
	signal cd_rst			:	std_logic;
	signal cd_rd_data		:	datatrain_rd;
	signal cd_wr_data		:	datatrain;
	-- split datatrain
	signal sd_rst			:	std_logic;
	signal sd_rd_data		:	datatrain;
	signal sd_wr_data		:	datatrain_wr;
	-- sorter
  	signal st_rst      		: 	std_logic;
  	signal st_rd_data  		: 	datatrain;
  	signal st_wr_data		: 	datatrain;
  	signal st_parity   		: 	std_logic;
  	-- counter
  	signal ct_rst    		: 	std_logic;
  	signal ct_en     		: 	std_logic;
  	signal ct_count  		: 	std_logic_vector((DATA_SIZE_MAX_BIT - 1) downto 0);
	-- flagger	
  	signal fl_rst     		: 	std_logic;     
  	signal fl_rd_data 		: 	datatrain;
  	signal fl_wr_data 		: 	datatrain;

-- generate components
	begin
	construct_datatrain1 : construct_datatrain
	port map( rst		=> cd_rst,
		rd_data		=> cd_rd_data,
		wr_data		=> cd_wr_data);

	split_datatrain1 : split_datatrain
	port map( rst		=> sd_rst,
		rd_data		=> sd_rd_data,
		wr_data		=> sd_wr_data);

	sorter1 : sorter
    	port map( clk       	=> clk,
      		rst       	=> st_rst,
           	parity    	=> st_parity,

      		rd_data    	=> st_rd_data,
      		wr_data   	=> st_wr_data);      


	counter1 : counter
    	port map( clk   	=> clk,
      		rst   		=> ct_rst,
      		en    		=> ct_en,

      		count 		=> ct_count);

	flagger1 : flagger
    	port map( clk        	=> clk,
      		rst         	=> fl_rst,

      		rd_data     	=> fl_rd_data,
      		wr_data    	=> fl_wr_data);


-- control process
	-- construct datatrain
  	st_rd_data 	<= inter_reg;
	
	
	process(clk, rst)
  		begin
		if (rst = '1') then
			-- reset components
      			st_rst    			<= '1';
      			fl_rst   			<= '1';
      			ct_rst   			<= '1';
			cd_rst				<= '1';
			sd_rst				<= '1';
	
      			-- prep for restart
      			processor_complete		<= '1';
      			ct_en        			<= '0';
      			state             		:= 0;
		elsif rising_edge(clk) then
			if state = 0 then
        			-- construct datatrain from input data
				cd_rd_data		<= rd_data;	-- pass input data to datatrain constructor
				cd_rst			<= '0';		-- construct datatrain
        			state 			:= 1;		-- change to state 1
        		elsif state = 1 then
				-- read in datatrain
				inter_reg  		<= cd_wr_data;	-- read datatrain into intermediate shift register
        			inter_size 		<= rd_size;
        			bcid_addr     		<= rd_addr;
	
        			if (processor_ready = '0') then 
					-- new data was read in
        			  	-- prep for state 2
        			  	ct_rst   	<= '1';
        			  	ct_en    	<= '0';
        			  	-- change to state 2
        			  	state 		:= 2;
        			end if;
			elsif state = 2 then 
				-- sort data
			        -- count number of clock cycles spent in state      
        			ct_rst 			<= '0';
        			ct_en  			<= '1';
	
        			-- feedback sorter
        			st_parity 		<= NOT st_parity;
        			inter_reg  		<= st_wr_data;
	
        			if (ct_count = inter_size) then 
					-- sort is complete; change to state 3
        		  		state		:= 3;
        			end if;
 			elsif state = 3 then
				-- flag data
        			fl_rd_data 		<= inter_reg;	-- pass data to flagger
        			state 			:= 4;		-- change to state 4
			elsif state = 4 then
				-- destruct datatrain
				sd_rd_data		<= fl_wr_data;	-- pass flagged datatrain to destructor
				sd_rst			<= '0';		-- destruct datatrain
				state			:= 5;		-- change to state 5
      			elsif state = 5 then
				-- output data
        			wr_data  		<= sd_wr_data;  -- pass destructed datatrain to output
        			processor_complete  	<= '1';
        			wr_addr		     	<= bcid_addr;
        			wr_size			<= inter_size; 	-- propagate size across
        			state 			:= 6;		-- change to state 6
	    	  	elsif state = 6 then
        			--check if data has been read-out
        			if processor_complete = '0' then 
					--data has been read
        				-- prep for state 0
        		  		processor_ready <= '1'; -- mark processor ready to receive new data
					cd_rst		<= '1';	-- reset constructor
					sd_rst		<= '1'; -- reset destructor
   	    	   			state 		:= 0;	-- return to state 0
   		     		end if;
			end if;
   		end if;
	end process;
end a;
