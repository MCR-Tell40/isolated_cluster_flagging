-- Bubble Sort
-- Even/Odd defined by parity of LSB
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 19/11/2015

-- 5 state process:
	-- state 0 = waiting for data
	-- state 1 = sorting data
	-- state 2 = flagging data
	-- state 3 = outputting sorted and flagged data
	-- state 4 = waiting for data to be read out


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.detector_constant_declaration.all;	-- constants file

entity data_processor is
	port(
		clk					: IN	std_logic;
		rst					: IN	std_logic;

		ready				: OUT	std_logic;
		rd_en				: IN	std_logic;
		rd_bcid				: IN	std_logic_vector(BCID_WIDTH - 1 downto 0);
		rd_data				: IN	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
		rd_size				: IN	std_logic_vector(RAM_WORD_SIZE - 1 downto 0);

		complete			: OUT	std_logic;
		wr_en				: IN	std_logic;
		wr_bcid				: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0);
		wr_data				: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
		wr_size				: OUT	std_logic_vector(RAM_WORD_SIZE - 1 downto 0)
	);
end data_processor;

architecture dataflow of data_processor is
-- define components
	component sorter is
	-- implementation of the bubble sorting algorithm
    	port(
			clk        		: IN	std_logic;
			rst        		: IN	std_logic;
      		parity      	: IN	std_logic; -- to determine whether to sort odd-even or even-odd
      		rd_data     	: IN	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
      		wr_data     	: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0)
		);
	end component;

	component counter is
	-- 8 bit counter to keep track of how many clock cycles have passed while the sorting is going on
    	port(
			clk				: IN 	std_logic;
			rst				: IN 	std_logic;
			en				: IN 	std_logic;
    		count 			: OUT	std_logic_vector(DATA_WORD_SIZE - 1 downto 0)
		);
  	end component;

  	component flagger is
	-- flags isolated SPPs
    	port(
			clk     		: IN  	std_logic;
			rst       		: IN  	std_logic;
      		rd_data   		: IN  	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
      		wr_data  		: OUT 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0)
		);
  	end component;

-- signals
	signal state			:	std_logic_vector(2 downto 0); -- three bits to count to 5
	signal inter_ready	:	std_logic;
	signal inter_complete	:	std_logic;
  	signal inter_reg   		: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);	-- internal shift register
  	signal inter_size  		: 	std_logic_vector(RAM_WORD_SIZE - 1 downto 0); 	-- number of SPPs in internal shift register
  	signal current_bcid 	: 	std_logic_vector(BCID_WIDTH - 1 downto 0);
	-- sorter
  	signal st_rst      		: 	std_logic;
  	signal st_rd_data  		: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
  	signal st_wr_data		: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
  	signal st_parity   		: 	std_logic;
  	-- counter
  	signal ct_rst    		: 	std_logic;
  	signal ct_en     		: 	std_logic;
  	signal ct_count  		: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
	-- flagger
  	signal fl_rst     		: 	std_logic;
  	signal fl_rd_data 		: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);
  	signal fl_wr_data 		: 	std_logic_vector(DATA_WORD_SIZE - 1 downto 0);

-- generate components
	begin
	sorter_component : sorter
    port map(
		clk       	=> clk,
      	rst       	=> st_rst,
      	parity    	=> st_parity,
  		rd_data    	=> st_rd_data,
  		wr_data   	=> st_wr_data
	);


	counter_component : counter
	port map(
		clk   		=> clk,
  		rst   		=> ct_rst,
  		en    		=> ct_en,
  		count 		=> ct_count
	);

	flagger_component : flagger
	port map(
		clk        	=> clk,
  		rst         => fl_rst,
  		rd_data     => fl_rd_data,
  		wr_data    	=> fl_wr_data
	);

	ready <= inter_ready;
	complete <= inter_complete;
	process(clk, rst)
	begin
		if (rst = '1') then
			-- reset components
      		st_rst    			<= '1';
      		fl_rst   			<= '1';
      		ct_rst   			<= '1';

      		-- prep for restart
				inter_ready		<= '1';
      		inter_complete			<= '0';
      		ct_en        	<= '0';
      		state          <= "000";
		elsif rising_edge(clk) then
			if state = "000" then
				-- read in data
				inter_reg  		<= rd_data;	-- read into intermediate shift register
        		inter_size 		<= rd_size;
        		current_bcid  	<= rd_bcid;

        		if inter_ready = '1' then
					-- new data was read in
        			-- prep for state 1
        			ct_en    	<= '1';
        			-- change to state 1
        			state 		<= "001";
        		end if;
			elsif state = "001" then
				-- sort data
			    -- count number of clock cycles spent in state
        		ct_rst 			<= '0';
        		ct_en  			<= '1';

        		-- feedback sorter
        		st_parity 		<= NOT st_parity;
        		inter_reg  		<= st_wr_data;

        		if (ct_count = inter_size) then
				-- sort is complete; change to state 2
        			state		<= "010";
        		end if;
 			elsif state = "010" then
				-- flag data
        		fl_rd_data 		<= inter_reg;	-- pass data to flagger
        		state 			<= "011";				-- change to state 3
			elsif state = "011" then
				-- output data
        		wr_data  		<= fl_wr_data;  -- pass destructed datatrain to output
        		inter_complete  		<= '1';			-- processor has finished processing data
        		wr_bcid		    <= current_bcid;
        		wr_size			<= inter_size; 	-- propagate size across
        		state 			<= "100";		-- change to state 4
	    	elsif state = "100" then
        		--check if data has been read-out
        		if inter_complete = '0' then
					--data has been read
        			-- prep for state 0
        		  	inter_ready <= '1'; -- mark processor ready to receive new data
   	    	   		state <= "000";	-- return to state 0
   		     	end if;
			end if;
   		end if;
	end process;
end dataflow;
