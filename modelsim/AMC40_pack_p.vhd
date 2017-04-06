library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library work;
use work.Constant_Declaration.all;
use work.Detector_Constant_Declaration.all;

package AMC40_pack is

------------------------------> Decoding 1/2 -------------------------------------------------------------------------------------------
-- length of the GBT frame : 80bits or 112 bits
constant FRAME_GBT_length : integer := FRAME_GBT_length_top;

-- bcid full length 
constant bcid_full_length : integer := 12;
-- bcid length 
constant bcid_length : integer := FE_bclk_bits;
-- bcid bit not used
constant bcid_diff : integer := bcid_full_length-bcid_length;

-- info in the header : truncation bit (1bit)
constant header_info_length : integer := FE_extra_bits;
-- data length information length in the header
constant datalength_length : integer := FE_size_bits;
-- data length unit for the datalength_length
constant data_length_unit : integer := channel_size;
-- header length : BCID (12bits) + header_info_length (1bit) + data_length (? bits)
constant header_length : integer := bcid_length + header_info_length + (datalength_length*use_data_length_field);
-- header length : BCID (12bits) + header_info_length (1bit) + data_length (? bits)
constant header_full_length : integer := bcid_full_length + header_info_length + (datalength_length*use_data_length_field);


------------------------------> Decoding [Data Flow definition] -------------------------------------------------------------------------------------------
-- width of the acq data for data processing
constant frame_data_for_data_processing_size : integer := FRAME_GBT_length+bcid_diff-(bcid_diff*(use_data_length_field))+(bcid_diff*(conv_integer(data_format_type(2))*conv_integer(data_format_type(1))*conv_integer(not(data_format_type(0)))));

-- depht of the memory between decoding and alignment
constant frame_data_for_data_processing_address_size : integer := 9;
------------------------------ Decoding [Data Flow definition] <-------------------------------------------------------------------------------------------


------------------------------> Decoding 2/2 -------------------------------------------------------------------------------------------

-- information frame through decoding
constant event_max_length : integer := 10000;
constant frame_type_length : integer := 4;
constant frame_nb_header_only_length : integer := 4;
constant frame_length_fifo_output_length : integer := 8;
constant frame_fifo_info_data_dec_length : integer := frame_type_length + frame_nb_header_only_length + frame_length_fifo_output_length; -- =16

--information_between_decoding and data alignemnt
constant nb_address_for_data_alignment_size : integer := 11;
constant information_for_data_alignment_size : integer := bcid_full_length + frame_data_for_data_processing_address_size + nb_address_for_data_alignment_size;

--length of event max
constant large_register_length : integer := FRAME_GBT_length+frame_data_for_data_processing_size;
-- length of the GBT frame : 128 bits
constant large_FRAME_GBT_length : integer := 128;

-- number of wrong bcid order successively max accepted before desync enabled
constant nb_max_error_bcid_order_continuous : integer := 4;
-- Maximum authorized for a jump BCID from FE data. Have to be < 28 (or need to change decoding block)
constant max_jump_BCID_authorized_constant : integer := 20;



------------------------------> Alignemnt -------------------------------------------------------------------------------------------
constant presence_bcid_frame_length : integer := 512;
constant address_presence_bcid_frame_length : integer := 9;  --> linked to presence_bcid_frame_length / correspond of how many bits it's needed to do presence_bcid_frame_length


------------------------------> TFC -------------------------------------------------------------------------------------------
constant TFC_data_size : integer := 64;
constant TFC_memory_address_size : integer := 12;

-- width of the tfc data for data processing
constant frame_tfc_for_data_processing_size : integer := TFC_data_size;


----------------------------->  deep fifo   -------------------------------------------------------------------------------------------
constant deep_fifo_GBT_IN : integer := 8;
constant deep_fifo_data_dec : integer := 9;
constant deep_fifo_align : integer := 9;
constant deep_fifo_info_data_dec : integer := deep_fifo_data_dec;

-----------------------------> ICF ----------------------------------------------------------------------------------------------------
type spp_array is array (63 downto 0) of std_logic_vector(31 downto 0);


end package;
