library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
library work;
use work.AMC40_pack.all;
use work.detector_constant_declaration.all;

package GDP_pack is

constant nb_DP_memory_input : integer := 3;

constant address_size_input_memory : integer := 9;
constant address_size_output_memory : integer := 9;
constant data_size_input_info_data : integer := nb_DP_memory_input + address_size_input_memory + datalength_length;

constant nb_fiber_max : integer := 32;
constant bit_position_over_256 : integer := 9;
constant nb_of_line : integer := 15;
constant information_memory_size : integer := 1 + bcid_full_length + nb_fiber_max + bit_position_over_256 + nb_of_line;

constant force_1_FSM : std_logic := '1';
constant nb_of_links : integer := conv_integer(active_fiber(0)) + conv_integer(active_fiber(1)) +conv_integer(active_fiber(2)) 
									+conv_integer(active_fiber(3)) +conv_integer(active_fiber(4)) + conv_integer(active_fiber(5));
constant nb_memory_out_data_processing : integer := nb_of_links*2 +1;

constant reverse_ok : std_logic := '0';

constant deep_fifo_data_dp : integer := 9;


end package;
