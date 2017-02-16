--eif_package.vhd
-- Define custom types for the EIF module


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.detector_constant_declaration.all;	-- constants file

package eif_package is

---Type definitions---
	-- datatrain is an array of MAX_FLAG_SIZE (128) vectors, each with 32 elements
	type datatrain 		is array (MAX_FLAG_SIZE - 1 downto 0)	of std_logic_vector(31 downto 0);

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

end eif_package;