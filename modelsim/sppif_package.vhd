--eif_package.vhd
-- Define custom types for the EIF module


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.detector_constant_declaration.all;	-- constants file

package sppif_package is

---Type definitions---
	-- datatrain is an array of GWT_WIDTH vectors, each with 32 elements
	type datatrain 		is array (GWT_WIDTH - 1 downto 0)	of std_logic_vector(31 downto 0);

	-- datatrain_rd is an array of 8 vectors, each with RD_WORD_SIZE (384) elements
	type datatrain_rd 	is array (7 downto 0)	of std_logic_vector(RD_WORD_SIZE - 1 downto 0);

	-- datatrain_wr is an array of 8 vectors, each with WR_WORD_SIZE (512) elements
	type datatrain_wr	is array (7 downto 0)	of std_logic_vector(WR_WORD_SIZE - 1 downto 0);

---Reset pattern definitions for two of the types (datatrain and datatrain_wr)---

	-- datatrain reset pattern
	-- construct vector of 32 zeroes as a datatrain reset element
	constant reset_pattern_spp	: std_logic_vector(31 downto 0)	:= (others => '0');
	-- construct vector of datatrain reset elements as a reset pattern for the datatrain
	constant reset_pattern_train	: datatrain	:= (others => reset_pattern_spp);

	-- datatrain_wr reset pattern
	-- construct vector of WR_WORD_SIZE zeroes as a datatrain_wr reset element
	constant reset_pattern_wr	: std_logic_vector(WR_WORD_SIZE - 1 downto 0)	:= (others => '0');
	-- construct vector of datatrain_wr reset elements as a reset pattern for the datatrain
	constant reset_pattern_wrtrain	: datatrain_wr	:= (others => reset_pattern_wr);

-- Custom types for array of data processors
	type dp_addr_vector	is array (DATA_PROCESSOR_COUNT - 1 downto 0)	of std_logic_vector(8 downto 0);
	type dp_rd_data_vector	is array (DATA_PROCESSOR_COUNT - 1 downto 0)	of datatrain_rd;
	type dp_wr_data_vector	is array (DATA_PROCESSOR_COUNT - 1 downto 0)	of datatrain_wr;
	type dp_size_vector	is array (DATA_PROCESSOR_COUNT - 1 downto 0)	of std_logic_vector(DATA_SIZE_MAX_BIT - 1 downto 0);

end sppif_package;
