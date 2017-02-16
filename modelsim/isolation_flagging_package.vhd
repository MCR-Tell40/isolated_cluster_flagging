-- Bubble Sort Function for deciding if a switch is needed
-- Author Nicholas Mead
-- Date Created 19/11/2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.detector_constant_declaration.all; 

-- Define Package
package isolation_flagging_package is 
	-- type def for array of std logic vectors
	type datatrain 			is array(MAX_FLAG_SIZE - 1 downto 0)	of std_logic_vector(31 downto 0);
	type datatrain_rd 		is array(7 downto 0) 			of std_logic_vector(RD_WORD_SIZE - 1 downto 0);
	type datatrain_wr 		is array(7 downto 0) 			of std_logic_vector(WR_WORD_SIZE - 1 downto 0);
	

	constant reset_pattern_spp    	: std_logic_vector(31 downto 0) 		:= (others => '0');
	constant reset_pattern_train  	: datatrain 					:= (others => reset_pattern_spp);
	
	constant reset_pattern_wr	: std_logic_vector(WR_WORD_SIZE - 1 downto 0) 	:= (others => '0');
	constant reset_pattern_wrtrain	: datatrain_wr 					:= (others => reset_pattern_wr);
end isolation_flagging_package;