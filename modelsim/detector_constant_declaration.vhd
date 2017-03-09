--detector_constant_declaration.vhd
-- Define detector constants


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package detector_constant_declaration is

  -------------- Incoming FE data ----------------------------------------------------------------------------------------
  constant data_format_type    		: std_logic_vector(2 downto 0) := "001";
  -- Select the data format expected:		
  -- 	001 for variable header length with dynamic data structure
  -- 	010 for fixed header length with dynamic data structure
  -- 	100 for fixed header length with fixed data structure
  -- 	101 for UT data structure (BXID + NoData + IsTrunc + NZS + Parity + Length + Data)
  
  constant simulation_fe_data_origin    : std_logic_vector(1 downto 0) := "01"; 
  -- Select the type of injection of data:
  -- 	00 nothing
  -- 	01 data from the generic data generator
  -- 	10 data from the txt file
  -- 	11 data from the sub-detector data generator

  -- FE specific configuration parameters
  constant channel_size                 : integer := 4; 
  constant number_of_channel            : integer := 500;
  constant FE_word_size                 : integer := (channel_size * number_of_channel);
  constant GBT_word_size                : integer := 124;
  constant GBT_header_size              : integer := 4;
  constant FE_bclk_bits                 : integer := 12;
  constant FE_size_bits                 : integer := 7;
  constant use_data_length_field	: integer range 0 to 1 := 1;  -- 0 no data_length, 1 data_length
  constant FE_extra_bits                : integer := 1;
  constant FE_header_size               : integer := FE_bclk_bits + FE_extra_bits + (FE_size_bits * use_data_length_field);

  constant FE_interface_fifo_depth      : std_logic_vector(7 downto 0) := X"A0"; 
  
  constant occupancy_01                 : real := 3.0;
  constant occupancy_02                 : real := 2.5;
  constant occupancy_03                 : real := 2.0;
  constant occupancy_04                 : real := 1.5;
  constant occupancy_05                 : real := 1.0;
  constant occupancy_06                 : real := 0.5;
  
  constant NZS_data_length	      	: integer := channel_size * number_of_channel;

  constant FE_BXID_offset               : unsigned(11 downto 0) 	:= X"000";
  constant SOL40_TO_FE_TFC_CMD_offset   : unsigned(11 downto 0) 	:= X"D48";

  constant Synch_Pattern_Frame_size     : integer := 10;
  constant SYNCH_PATTERN_frame          : std_logic_vector(9 downto 0) 	:= "1011010011";

  constant active_fiber 		: std_logic_vector(47 downto 0) := x"000000000007";
  
  -- TFC to FE specific configurations parameters
 
  constant FE_reset_wait                : std_logic_vector(15 downto 0) := X"00FA"; -- 250 clock cycles
  -- number of clock cycles to wait after one FE RESET command
  
  constant NZS_enb              	: std_logic                     := '1';
  -- enable/disable NZS trigger
  constant NZS_consecutive_enb  	: std_logic                     := '0';
  -- number of consecutive NZS triggers
  constant NZS_TAE_wait_clkcycle	: std_logic_vector(31 downto 0) := X"00000010";
  -- number of clock cycles to wait after one or more consecutive NZS triggers

  -- CALIBRATION TRIGGERS
  --
  constant CALIBTRG_A_period    	: std_logic_vector(15 downto 0) := X"0001";
  -- periodicity as a number of orbits (1 = every orbit etc.)
  constant CALIBTRG_A_bxid      	: std_logic_vector(15 downto 0) := X"0C0F";
  -- BXID on which calibration trigger will trigger
  constant CALIBTRG_A_enb       	: std_logic                     := '1';
  -- enable/disable calibration trigger

  constant CALIBTRG_B_period    	: std_logic_vector(15 downto 0) := X"0001";
  constant CALIBTRG_B_bxid      	: std_logic_vector(15 downto 0) := X"04AF";
  constant CALIBTRG_B_enb       	: std_logic                     := '0';
  constant CALIBTRG_C_period    	: std_logic_vector(15 downto 0) := X"0001";
  constant CALIBTRG_C_bxid      	: std_logic_vector(15 downto 0) := X"09DF";
  constant CALIBTRG_C_enb       	: std_logic                     := '0';
  constant CALIBTRG_D_period    	: std_logic_vector(15 downto 0) := X"0001";
  constant CALIBTRG_D_bxid      	: std_logic_vector(15 downto 0) := X"020F";
  constant CALIBTRG_D_enb       	: std_logic                     := '0';
  -- same as Calib A
  
  -- SPECIAL ENABLES
  constant SNAPSHOT_enb         	: std_logic                     := '1';
  -- enable SNAPSHOT command	
  constant SNAPSHOT_interval    	: std_logic_vector(15 downto 0) := X"37B0";
  -- number of clock cycles between two SNAPSHOT commands
  constant SYNCH_enb            	: std_logic                     := '1';
  -- enable SYNCH command
  constant SYNCH_length         	: std_logic_vector(15 downto 0) := X"000A";
  -- number of consecutive SYNCH triggers (in clock cycles)
  constant SYNCH_wait           	: std_logic_vector(15 downto 0) := X"0002";
  -- number of consecutive clock cycles to wait after one or more SYNCH commands
  constant BX_VETO_enb          	: std_logic                     := '1';
  -- enable BX_VETO command (ignore if not used in FE)
  constant HEADER_ONLY_enb      	: std_logic                     := '1';
  -- enable HEADER_ONLY command (ignore if not used in FE)

  -- Introduce voluntary BXID bugs 
  -- NOTE 1: if both skip and swap are enabled, skip has priority
  -- NOTE 2: if skip_interval and swap_interval have the same value, skip has priority
  constant skip_BXID                    : std_logic_vector(5 downto 0) 	:= "000000";
  constant skip_BXID_interval           : std_logic_vector(15 downto 0) := X"0545";
  constant swap_BXID                    : std_logic_vector(5 downto 0)  := "000000";
  constant swap_BXID_interval           : std_logic_vector(15 downto 0) := X"0641";
  constant skip_BXID_jump               : std_logic_vector(11 downto 0) := X"00C";

  ---------SPP Isolation Flagging----------------------------------
  -- Usage: (CONSTANT - 1 downto 0)

  -- surely the following RD_ and WR_ constants should be equal to each other if this is to a drop-in module! 
  constant RD_WORD_SIZE         	: integer := 384;
  constant RD_SPP_SIZE          	: integer := 24;
  constant RD_SPP_PER_BCID      	: integer := 512;

  constant WR_WORD_SIZE         	: integer := 512;
  constant WR_SPP_SIZE          	: integer := 32;
  constant WR_SPP_PER_BCID      	: integer := 512;

  -- not sure what this is supposed to represent
  constant DATA_SIZE_MAX_BIT    	: integer := 8;

  -- taken from Bypass Controller generics - are the numbers correct?
  constant ADDR_PER_RAM 		: integer := 32;
  constant MAX_RAM_ADDR_STORE 		: integer := 512;
  constant SPP_PER_ADDR 		: integer := 16;

--------------------------------------------------------------------
  -- checked by Donal Murray below here
  -- From count ram
  constant SPP_BCID_WIDTH		: integer := 9; 	-- number of bits taken up by SPP BCID
  constant COUNT_RAM_WORD_SIZE  	: integer := 8;		-- number of bits needed to provide the number of SPPs associated with this BCID
  constant BUFFER_LIFETIME      	: integer := 2048;	-- maximum number of clock cycles for each data processor to complete its job

  constant DATA_PROCESSOR_COUNT 	: integer := 16;	-- number of data processors
  -- FIFO
  constant SPP_PER_BCID			: integer := 16;	-- max number of SPPs in each BCID
  constant FIFO_DEPTH			: integer := 512;	-- number of BCIDs able to be stored in FIFO at any time
  -- Maximum address which I think should be 512 but nick and ben have as 128
  constant MAX_ADDR 			: integer := 128; 	-- Nick and Ben's guess

end detector_constant_declaration;