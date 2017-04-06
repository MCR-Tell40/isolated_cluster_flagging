LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

PACKAGE Detector_Constant_Declaration IS

  -------------- Type of MiniDAQ --------------------
  constant MiniDAQ_40MHz       : std_logic := '0';
  -- 0 : MiniDAQ with a 80MHz quartz
  -- 1 : MiniDAQ with a 40MHz quartz


  -------------- Fibers connected to the TELL40 ------------------
  --constant active_fiber 		: std_logic_vector(47 downto 0) := x"0000000003FF"; -- for simulation mode
  constant active_fiber 		: std_logic_vector(47 downto 0) := x"000000ffffc0"; -- for compilation mode
  --Bit 0 correspond to the fiber link 1, set 1 to this bit if a fiber is connected
  --Bit 1 correspond to the fiber link 2, set 1 to this bit if a fiber is connected
  -- ...
  constant working_fiber 		: std_logic_vector(47 downto 0) := active_fiber;
  --Bit 0 correspond to the fiber link 1, set 0 to this bit if the fiber is connected but not working
  --Bit 1 correspond to the fiber link 2, set 0 to this bit if the fiber is connected but not working
  -- ...
  --constant fiber_mapping_tfc_or_acq 	: std_logic_vector(47 downto 0) := x"000000001C00"; -- for simulation mode
  constant fiber_mapping_tfc_or_acq 	: std_logic_vector(47 downto 0) := x"00000000003f"; -- for compilation mode
  --Bit 0 correspond to the fiber link 1, set 1 to this bit if a the fiber is used for TFC, set 0 if the fiber is used for acquisition
  --Bit 1 correspond to the fiber link 2, set 1 to this bit if a the fiber is used for TFC, set 0 if the fiber is used for acquisition
  -- ...
  
  
  -------------- Simulation injection selection ----------------
  constant simulation_fe_data_origin    : std_logic_vector (1 downto 0):= "01"; 
  -- 00 nothing
  -- 01 data from the generic data generator
  -- 10 data from the txt file
  -- 11 data from the sub-detector data generator
  
  
  -------------- FE specific configuration parameters ---------------------
  constant channel_size                 	: INTEGER := 30;
  constant number_of_channel            	: INTEGER := 10;
  constant FE_word_size                 	: INTEGER := (channel_size*number_of_channel);
  constant GBT_word_size                	: INTEGER := 124;
  constant GBT_header_size             	    : INTEGER := 4;
  constant FE_bclk_bits                 	: INTEGER := 12;
  constant FE_size_bits                 	: INTEGER := 8;
  constant use_data_length_field 	      	: INTEGER range 0 to 1 := 0;  -- 0 no data_length, 1 data_length
  constant FE_extra_bits                	: INTEGER := 4;
  constant FE_header_size               	: INTEGER := FE_bclk_bits+FE_extra_bits+(FE_size_bits*use_data_length_field);

  constant NZS_data_length	      	  	    : INTEGER := channel_size*number_of_channel;
  constant Synch_Pattern_Frame_size     	: INTEGER := 10;
  constant SYNCH_PATTERN_frame          	: std_logic_vector(Synch_Pattern_Frame_size-1 downto 0) := "1011010011";
  
  
  -------------- FE data format -------------------------
  constant data_format_type    : std_logic_vector(2 downto 0) := "100";
  -- 001 for variable header length with dynamic data structure
  -- 010 for fixed header length with dynamic data structure
  -- 100 for fixed header length with fixed data structure
  -- 101 for UT data structure (BXID + NoData + IsTrunc + NZS + Parity + Length + Data)
  -- 110 for fixed header length with dynamic data structure with FE_header_size = channel_size and both GBT_word_size aligned
  --		and for SCIFI data structure but aligned to 28 bits thanks to the constant "bit_alignment"
  
  constant data_format_order	 : std_logic       := '1';
  -- Select the data bit ordering of a GBT frame FE data format / See the data format documentation for more details : https://lbredmine.cern.ch/documents/7
  -- 0 : Header starts on LSB side
  -- 1 : Header starts on MSB side

  --> for SciFi data format
  constant bit_alignment        : INTEGER       := 28;
  --> for FF data format : fill the frame with a counter for each channel
  constant FF_full_frame_filled : std_logic := '1';--0
  --> for all format, put random data in channels
  constant random_data_in_FE_channels : std_logic := '0';
  --> for UT data format
  constant FRAME_GBT_length_top : INTEGER := GBT_word_size;		
  -- UT : FRAME_GBT_length_top: INTEGER := 40;
  -- other : FRAME_GBT_length_top: INTEGER := GBT_word_size;	
  constant final_UT_data_format : std_logic := '1'; 
  -- 0 : compliant with the generic data generator; 
  -- 1 : compliant with the 2 parity bits and the small IDLE frame (UT data format)

  constant keep_full_frame_gdp : std_logic := '0';
  -- 0 : truncate BXID on data in GDP block
  -- 1 : keep data full frame in GDP block
  
  constant one_event_kept_over_X_constant : std_logic_vector(31 downto 0) := x"000001F4";
  constant initial_BCID_to_start_trigger_constant : std_logic_vector(31 downto 0) := x"000001F4"; 
  constant trigger_test_enable_constant : std_logic := '0'; -- should be '1' for simulation
  
  -------------- Data processing output data format ----------------
  constant velo_data_header                 : std_logic_vector(3 downto 0) := "1010";
  constant velo_idle_header                 : std_logic_vector(3 downto 0) := "0110";

  constant Event_ID_size 					: integer := 64;
  --> global data length information in the global header
  constant global_data_length_length 		: natural := 20;
  --> Data processing output global header length :  
  constant global_header_length 			: natural :=  global_data_length_length + 12;-- 20+bcid_full_length(=12) = 32b



  
  -------------- Choice PCIe or 10G MiniDAQ output interface -------------------------
  constant PCIe_interface_enable 			: integer := 0; 				--tag_PCIe_interface_enable(do not erase the tag, used for checking)
  -- 0 : output interface is 10GbE
  -- 1 : output interface is PCIe
  constant Output_data_width_data_processing 		: integer := 64 + 192*PCIe_interface_enable;
  constant Output_data_width_data_processing_PCIe : integer := 256;
  constant Output_data_width_data_processing_10GbE : integer := 64;
  
  
  
  -------------- FE parameters ----------------
  -- Number of FE cores (in simulation this must be fixed to 6)
  constant FE_interface_fifo_depth      : std_logic_vector(7 downto 0) := X"A0"; 
  type occupancy_t                      is array(23 downto 0) of real;
  -- Be careful about the initialization, remove occupancy initialization accordingly
  constant occupancy                    : occupancy_t := (5.0,4.0,3.0,2.5,1.0,0.5,5.0,4.0,3.0,2.5,1.0,0.5,5.0,4.0,3.0,2.5,1.0,0.5,5.0,4.0,3.0,2.5,1.0,0.5);
  constant FE_BXID_offset               : unsigned(11 downto 0) := X"000";
  constant SOL40_TO_FE_TFC_CMD_offset   : unsigned(11 downto 0) := X"D48";
  constant FW_with_FE                   : std_logic     := '1';--'1';
  constant SOL40_with_SCA_core          : std_logic_vector(47 downto 0) := x"00000000000f"; --orig = 38                
  constant SOL40_with_SC_VELO_core      : std_logic     := '1';  --orig = 1

  
  -------------- TFC to FE specific configurations parameters -----------
  -- number of clock cycles to wait after one FE RESET command
  constant FE_reset_wait                : std_logic_vector(15 downto 0) := X"00FA"; -- 250 clock cycles
  -- enable/disable NZS trigger
  constant NZS_enb              : std_logic                     := '1';
  -- number of consecutive NZS triggers
  constant NZS_consecutive_enb  : std_logic                     := '0';
  -- enable/disable consecutive TAE triggers
  constant TAE_enb              : std_logic                     := '0';     
  -- number of consecutive NZS triggers or number of consecutive TAE triggers
  constant window               : integer range 0 to 15 := 7;     
  -- number of clock cycles to wait after one or more consecutive NZS triggers
  constant NZS_TAE_wait_clkcycle: std_logic_vector(31 downto 0) := X"0000000f"; --X"00000010";
  -- define which trigger should generate an NZS command
    -- list here
    --7 is random trigger D 
    --8 is random trigger C
    --9 is random trigger A
    --A is periodic trigger 2
    --B is periodic trigger 1
    --D is calibration trigger (any)
	 
    constant TRG_TYPE_for_NZS      : std_logic_vector(3 downto 0)  := X"A";


    -------------- CALIBRATION TRIGGERS -----------------------------------------------------------------------------------
	-- periodicity as a number of orbits (1 = every orbit etc.)
    constant CALIBTRG_A_period    : std_logic_vector(15 downto 0) := X"0000";
    -- BXID on which calibration trigger will trigger
    constant CALIBTRG_A_bxid      : std_logic_vector(15 downto 0) := X"0C0F";
    -- enable/disable calibration trigger
    constant CALIBTRG_A_enb       : std_logic                     := '1';
    constant CALIBTRG_B_period    : std_logic_vector(15 downto 0) := X"0001";
    constant CALIBTRG_B_bxid      : std_logic_vector(15 downto 0) := X"04AF";
    constant CALIBTRG_B_enb       : std_logic                     := '0';
	constant CALIBTRG_C_period    : std_logic_vector(15 downto 0) := X"0001";
    constant CALIBTRG_C_bxid      : std_logic_vector(15 downto 0) := X"09DF";
    constant CALIBTRG_C_enb       : std_logic                     := '0';
    constant CALIBTRG_D_period    : std_logic_vector(15 downto 0) := X"0001";
    constant CALIBTRG_D_bxid      : std_logic_vector(15 downto 0) := X"020F";
    constant CALIBTRG_D_enb       : std_logic                     := '0';
	
	
--    constant TRG_TYPE_for_NZS      : std_logic_vector(3 downto 0)  := X"A";  
--
--  -------------- CALIBRATION TRIGGERS -------------
--  -- periodicity as a number of orbits (1 = every orbit etc.)
--  constant CALIBTRG_A_period    : std_logic_vector(15 downto 0) := X"0001";
--  -- BXID on which calibration trigger will trigger
--  constant CALIBTRG_A_bxid      : std_logic_vector(15 downto 0) := X"0C0F";
--  -- enable/disable calibration trigger
--  constant CALIBTRG_A_enb       : std_logic                     := '1';
--  constant CALIBTRG_B_period    : std_logic_vector(15 downto 0) := X"0001";
--  constant CALIBTRG_B_bxid      : std_logic_vector(15 downto 0) := X"04AF";
--  constant CALIBTRG_B_enb       : std_logic                     := '0';
--  constant CALIBTRG_C_period    : std_logic_vector(15 downto 0) := X"0001";
--  constant CALIBTRG_C_bxid      : std_logic_vector(15 downto 0) := X"09DF";
--  constant CALIBTRG_C_enb       : std_logic                     := '0';
--  constant CALIBTRG_D_period    : std_logic_vector(15 downto 0) := X"0001";
--  constant CALIBTRG_D_bxid      : std_logic_vector(15 downto 0) := X"020F";
--  constant CALIBTRG_D_enb       : std_logic                     := '0';

    -------------- CALIBRATION TRIGGERS -----------------------------------------------------------------------------------
    constant PERTRG_01_period     : std_logic_vector(15 downto 0) := X"0001";
    constant PERTRG_01_bxid       : std_logic_vector(15 downto 0) := X"0050";
    constant PERTRG_01_enb        : std_logic                     := '0';
    constant PERTRG_02_period     : std_logic_vector(15 downto 0) := X"0300";
    constant PERTRG_02_bxid       : std_logic_vector(15 downto 0) := X"1000";
    constant PERTRG_02_enb        : std_logic                     := '1';
    constant PER_SYNCH_period     : std_logic_vector(15 downto 0) := X"0001";
    constant PER_SYNCH_bxid       : std_logic_vector(15 downto 0) := X"0100";
    constant PER_SYNCH_enb        : std_logic                     := '0';
  
  -------------- SPECIAL ENABLES ------------------
  constant SNAPSHOT_enb         : std_logic                     := '1';
  -- enable SNAPSHOT command
  constant SNAPSHOT_interval    : std_logic_vector(15 downto 0) := X"37B0";
  -- number of clock cycles between two SNAPSHOT commands
  constant SYNCH_enb            : std_logic                     := '1';
  -- enable SYNCH command
  constant SYNCH_length         : std_logic_vector(15 downto 0) := X"000A";
  -- number of consecutive SYNCH triggers (in clock cycles)
  constant SYNCH_wait           : std_logic_vector(15 downto 0) := X"0002";
  -- number of consecutive clock cycles to wait after one or more SYNCH commands
  constant BX_VETO_enb          : std_logic                     := '0';--'1';
  -- enable BX_VETO command (ignore if not used in FE)
  constant HEADER_ONLY_enb      : std_logic                     := '1';
  -- enable HEADER_ONLY command (ignore if not used in FE)


  -- Introduce voluntary BXID bugs 
  -- NOTE 1: if both skip and swap are enabled, skip has priority
  -- NOTE 2: if skip_interval and swap_interval have the same value, skip has priority
  constant skip_BXID                    : std_logic    := '0';
  constant repeat_BXID                  : std_logic    := '0';
  constant skip_BXID_interval           : std_logic_vector(15 downto 0)   := X"0545";
  constant swap_BXID                    : std_logic    := '0';
  constant swap_BXID_interval           : std_logic_vector(15 downto 0)   := X"0641";
  constant skip_BXID_jump               : std_logic_vector(11 downto 0)   := X"100";--X"00C";


  -----------------  SPECIAL CONSTANTS FOR VELO --------------------------------
  
  CONSTANT Desired_Consec_Correct_Headers	: INTEGER := 23; -- Number of correct headers found after which we declared to have found the correct boundary
  CONSTANT Nb_Accepted_False_Header		: INTEGER := 4;  -- Number of false header we accept to find within "Nb_Checked_Header" checked headers without declaring to have lost the boundary
  CONSTANT Nb_Checked_Header				: INTEGER := 64;

  constant spp_pre_router_size : integer := 30;
  constant spp_post_router_size : integer := 24;

  constant ChipID_0 : std_logic_vector(2 downto 0) := std_logic_vector(to_signed(0, 3));
  constant ChipID_1 : std_logic_vector(2 downto 0) := std_logic_vector(to_signed(1, 3));
  constant ChipID_2 : std_logic_vector(2 downto 0) := std_logic_vector(to_signed(2, 3));
  constant ChipID_3 : std_logic_vector(2 downto 0) := std_logic_vector(to_signed(3, 3));
  constant ChipID_4 : std_logic_vector(2 downto 0) := std_logic_vector(to_signed(4, 3));
  constant ChipID_5 : std_logic_vector(2 downto 0) := std_logic_vector(to_signed(5, 3));

  constant Link0_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_0;
  constant Link1_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_0;
  constant Link2_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_0;
  constant Link3_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_0;
  constant Link4_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_1;
  constant Link5_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_1;
  constant Link6_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_2;
  constant Link7_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_3;
  constant Link8_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_4;
  constant Link9_belongs_to_ChipID : std_logic_vector(2 downto 0) := ChipID_5;

  -- VELO ROUTER CONSTANTS-----

---- msb4
  constant bcid_range			: integer := 9;		-- the range of BCID from the velopix
  constant spp_width_0			: integer := 33;		-- Super Pixel Packet width at the input of the msb4 block
  constant spp_width_1			: integer := 32;		-- Super Pixel Packet width at the output of the first column of the msb4 block
  constant spp_width_2			: integer := 31;		-- Super Pixel Packet width at the output of the second column of the msb4 block
  constant spp_width_3			: integer := 30;		-- Super Pixel Packet width at the output of the third column of the msb4 block
  constant spp_width_4			: integer := 29;		-- Super Pixel Packet width at the output of the fourth column of the msb4 block
  constant bit_compare_msb4	: integer := 26;		-- position of the BCID(5) inside the data bus in the msb4 block
  
  -- two_x_two fifos
  constant sppfifo_depth		: integer := 9;		-- 2**sppfifo_depth is the fifo depth used in two_x_two_i components
  
  -- spp_ram	size = 384 Kbit = 19.2 M20K blocks <=> write size = read size <=> 24 * 2**14 = 24*2**4 * 2**10 <=> sppram_w_width * 2**sppram_w_depth = sppram_r_width * 2**sppram_r_depth + 
  constant sppram_width_ratio	: integer := 4;	-- 2**sppram_width_ratio defines the relationship between sppram_r_width and sppram_w_width
  constant sppram_w_seg_size		: integer := 9; 	-- segment size => 2**sppram_w_seg_size is the maximum number of events stored in a ram segment
  constant sppram_w_seg_num		: integer := 5;		-- 2**sppram_w_seg_num is the number of segments in the sppram
  constant sppram_w_depth			: integer := sppram_w_seg_size + sppram_w_seg_num;		-- 2**sppram_w_depth is number of write-words in the sppram (sppram_w_depth = sppram_w_seg_size + sppram_w_seg_num)
  constant sppram_w_width			: integer := 24;		-- spp_width-bcid_range 33-9  write-words width
  constant sppram_r_depth			: integer := sppram_w_depth - sppram_width_ratio;		-- 2**sppram depth is the number of read-words in the sppram
  constant sppram_r_width			: integer := sppram_w_width*2**sppram_width_ratio;		-- sppram read-words width

---- lsb5	num_one_x_one * tirtytwo_x_one = 2**bcid_range
  constant spp_width_5			: integer := 28;		-- Super Pixel Packet width at the output of the first column of the lsb5 block
  constant spp_width_6			: integer := 27;		-- Super Pixel Packet width at the output of the second column of the lsb5 block
  constant spp_width_7			: integer := 26;		-- Super Pixel Packet width at the output of the third column of the lsb5 block
  constant spp_width_8			: integer := 25;		-- Super Pixel Packet width at the output of the fourth column of the lsb5 block
  constant spp_width_9			: integer := 24;		-- Super Pixel Packet width at the output of the fifth column of the lsb5 block
  constant bit_compare_lsb5	: integer := 21;		-- position of the BCID(0) inside the data bus in the lsb5 block
  constant num_one_x_one		: integer := 16;		-- number of one_x_one elements
  constant num_thirtytwo_x_one		: integer := 32;		-- number of tirtytwo_x_one elements. 
  constant BIDReset_delay		: integer := 2048;
  -- ev_ram size = 
  constant evram_depth		: integer := bcid_range; -- the evram depth is the number of BCID stored in a sppram to be tracked
  constant evram_width		: integer := sppram_w_seg_size; -- 2**evram_depth s the maximum number of events stored in a ram segment
  
  -- Bunch ID reset pipeline
  constant BIDresetpipeline_delay		: integer := 128;		-- The reset of the event counters of thirtytwo_x_one components are delayed by 128x6.25ns = 1/16x512x25ns = the time to arrive the 32 BID SPP for every thirtytwo_x_one block

  -- number of clocks to wait before to multiplex the event counter
  constant rdevcount_delay	: integer := 32;		-- the number of clocks before the BIDreset_delayed arrival for event count multiplexing

  -- Data_processing_out
  
  --- PRE-ROUTER CONSTANTS-----
  constant num_i_links	: integer := 10;
  TYPE i_data_type is array (0 to num_i_links - 1) of std_logic_vector(123 DOWNTO 0);	--frame_data_for_data_processing_size
  TYPE i_ChipID_type is array (0 to num_i_links - 1) of std_logic_vector(2 downto 0);
  TYPE o_data_type is array (0 to num_i_links - 1) of std_logic_vector(spp_width_0 - 1 DOWNTO 0);
  
  
  -- POST_ROUTER constants --------
  constant delay_reading_sppram : natural := 3;
  type PR_counter_address_type is array (0 to num_one_x_one-1) of std_logic_vector(8 downto 0) ;
  type PR_data_address_type is array (0 to num_one_x_one-1) of std_logic_vector(9 downto 0) ;
  type PR_sppram_id_type is array (0 to num_one_x_one-1) of std_logic_vector(bcid_range - sppram_w_seg_num - 1 downto 0) ;
  type PR_header_type is array (0 to num_one_x_one-1) of std_logic_vector(31 downto 0) ;
  type PR_evcounter_type is array (0 to num_thirtytwo_x_one- 1) of integer;
  
  
  
  
END Detector_Constant_Declaration;

