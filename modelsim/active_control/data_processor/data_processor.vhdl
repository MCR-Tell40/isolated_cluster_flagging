-- Bubble Sort Tops
-- Even/Odd defined by parity of LSB
-- Author Ben Jeffrey, Nicholas Mead
-- Date Created 19/11/2015

-- for processes going to implement 4 state process
-- state 0 = waiting for data
-- state 1 = sorting data
-- state 2 = flag data
-- state 3 = ship data out
-- state 4 = wait for data to be read out

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.isolation_flagging_package.all;
use work.detector_constant_declaration.all;


entity data_processor is
port(
    	-- Common control signals
	clk, rst		: IN    std_logic;
    
    	-- Data transfer
    	data_in       		: IN 	dataTrain; --data_in
    	data_out       		: OUT 	dataTrain; --data_out
    	data_size_in   		: IN   	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0);
    	data_size_out  		: OUT  	std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0);


    	-- Data processor active flag
    	processor_ready       	: INOUT std_logic;
    	processor_complete    	: INOUT std_logic;

    	-- BCID address
    	bcid_addr_in        	: IN    std_logic_vector(8 downto 0); 
    	bcid_addr_out       	: OUT   std_logic_vector(8 downto 0)
);
end data_processor;

architecture a of data_processor is
	component sorter is
    	port(
      		clk, rst        : IN	std_logic; 
      		parity        	: IN	std_logic; --high when odd
      		data_in       	: IN	dataTrain;
      		data_out      	: OUT	dataTrain
	);
	end component;

	component counter_8bit is
    	port(
    		clk, rst, en	: IN 	std_logic;
    		count 		: OUT	std_logic_vector((DATA_SIZE_MAX_BIT - 1) downto 0)
    	);
  	end component;

  	component flagger is
    	port(
      		clk, rst       	: IN  	std_logic;
      		data_in   	: IN  	datatrain;
      		data_out  	: OUT 	datatrain
    	);
  	end component;

  -- Internal Signals
  	signal internal_clk   	: 	std_logic;
  	signal internal_reg   	: 	datatrain;
  	signal internal_size  	: 	std_logic_vector((DATA_SIZE_MAX_BIT - 1) downto 0); 
		
  	shared variable state 	: 	integer range 0 to 4;
			
  	signal bcid_addr 	: 	std_logic_vector(8 downto 0);
	
  	signal sorter_rst      	: 	std_logic;
  	signal sorter_data_in  	: 	datatrain;
  	signal sorter_data_out 	: 	datatrain;
  	signal sorter_parity   	: 	std_logic;
  		
  	signal counter_rst    	: 	std_logic;
  	signal counter_en     	: 	std_logic;
  	signal counter_value  	: 	std_logic_vector((DATA_SIZE_MAX_BIT - 1) downto 0);
	
  	signal flagger_rst     	: 	std_logic;     
  	signal flagger_data_in 	: 	datatrain;
  	signal flagger_data_out : 	datatrain;

	begin
	sorter1 : sorter
    	port map (
    	  	clk       	=> internal_clk,
      		rst       	=> sorter_rst,
      
      		data_in    	=> sorter_data_in,
      		data_out   	=> sorter_data_out,      
      
      		parity    	=> sorter_parity
    	);

	counter1 : counter_8bit
    	port map (
      		clk   		=> internal_clk,
      		rst   		=> counter_rst,

      		en    		=> counter_en,
      		count 		=> counter_value
    	);

	flagger1 : flagger
    	port map (
      		clk        	=> internal_clk,
      		rst         	=> flagger_rst,
      	
      		data_in     	=> flagger_data_in,
      		data_out    	=> flagger_data_out
      	);


---------------------- Control Process ---------------------------
  	-- Constant Signal Propagation
  	internal_clk	<= clk;
  	sorter_data_in 	<= internal_reg;
	
	process(clk, rst)
  		begin
		if (rst = '1') then
			-- reset componants
      			sorter_rst    			<= '1';
      			flagger_rst   			<= '1';
      			counter_rst   			<= '1';
	
      			-- prep for restart
      			processor_complete		<= '1';
      			counter_en        		<= '0';
      			state             		:= 0;
		elsif rising_edge(clk) then
			if state = 0 then
        			-- collect data
        			internal_reg  		<= data_in;
        			internal_size 		<= data_size_in;
        			bcid_addr     		<= bcid_addr_in;
	
        			if (processor_ready = '0') then -- new data was read in
        			  	-- prep for state 1
        			  	counter_rst   	<= '1';
        			  	counter_en    	<= '0';
        			  	-- move to next state
        			  	state 		:= 1;
        			end if;
			elsif state = 1 then -- sort data
			        -- count time in state      
        			counter_rst 		<= '0';
        			counter_en  		<= '1';
	
        			-- feedback sorter
        			sorter_parity 		<= NOT sorter_parity;
        			internal_reg  		<= sorter_data_out;
	
        			if (counter_value = internal_size) then 
					-- sort is complete; move to next state
        		  		state		:= 2;
        			end if;
 			elsif state = 2 then
        			flagger_data_in 	<= internal_reg;
        			state 			:= 3;
	
      			elsif state = 3 then
        			data_out  		<= flagger_data_out;  
        			processor_complete  	<= '1';
        			BCID_addr_out     	<= BCID_addr;
        			data_size_out 		<= internal_size; -- propagate size across
        			state 			:= 4;
	    	  	elsif state = 4 then
        			--check if data has been read-out
        			if processor_complete = '0' then --data has been read
        				-- prep for state 0
        		  		processor_ready 	<= '1';
   	    	   			state 		:= 0;
   		     		end if;
			end if;
   		end if;
	end process;
end a;
