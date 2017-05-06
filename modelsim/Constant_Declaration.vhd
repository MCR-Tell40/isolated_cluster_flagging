LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;

library work;
use work.Detector_Constant_Declaration.all;

PACKAGE Constant_Declaration IS

----------------------------- Specific for SOL40 links ---------------------------------------------------------------------
  constant NUM_SOL40_links              : integer       := 24;
  constant NUM_FE_links                 : integer       := 24;
  constant SOL40_with_SCA_debugger      : std_logic     := '0';
  constant delay_fibers                 : time          := 500 ns;
  constant delay_fibers_injection       : time          := 200 us;


  -- Data generators settings
  constant shift_poissonian             : real  := 0.1;
  constant thresh_emptyempty            : real  := 0.8;
  constant min_uniform                  : real  := 0.0;
  constant max_uniform                  : real  := real(channel_size);

  -- TELL40 emulator alignment settings
  constant TELL40_BXID_Delay            : integer       := 0;
  constant TELL40_TFC_CMD_offset        : integer       := 10;

  -- Select which FE module to write statistics from
  -- set bit 0 = FE_core_01, set bit 1 = FE_core_02 etc...
  constant write_statistics             : std_logic_vector(NUM_FE_links-1 downto 0) := (23 downto 0 =>'1');
  -- Select if you need to generate a TFC commands file
  constant write_tfc_in_a_file          : std_logic     := '1';

------------------------------ ECS -------------------------------------------------------------------------------------------
-- BAR0 addresses width
  constant ECS_address_size       : integer := 25;
-- BAR0 data width
  constant ECS_data_size          : integer := 32;
 
  -- VELO 
  constant NUM_VELO_links               : integer       := 3;  -- = num chips per GBTX
  type ECS_data_VELOlink_array_t        is array(5 downto 0) of std_logic_vector(ECS_data_size-1 downto 0);
  type ECS_data_VELOlink_valid_array_t  is array(5 downto 0) of std_logic;
 
----------------------------- Types definition for SOL40 ---------------------------------------------------------------------
  type FE_SOL40link_array_t	        is array(NUM_SOL40_links-1 downto 0) of std_logic_vector(84-1 downto 0);
  type FE_SOL40link_valid_array_t       is array(NUM_SOL40_links-1 downto 0) of std_logic;
  type TFC_SOL40link_array_t	        is array(NUM_SOL40_links-1 downto 0) of std_logic_vector(64-1 downto 0);
  type TFC_SOL40link_valid_array_t      is array(NUM_SOL40_links-1 downto 0) of std_logic;
  type ECS_data_SOL40link_array_t	is array(NUM_SOL40_links-1 downto 0) of std_logic_vector(0 to ECS_data_size-1);
  type ECS_data_SOL40link_valid_array_t is array(NUM_SOL40_links-1 downto 0) of std_logic;
  type FE_array_t	                is array(NUM_FE_links-1 downto 0) of std_logic_vector(GBT_word_size-1+GBT_header_size downto 0);
  type FE_valid_array_t                 is array(NUM_FE_links-1 downto 0) of std_logic;
  type FE_array_top_header_t            is array(NUM_FE_links-1 downto 0) of std_logic_vector(1 downto 0);
  type FE_array_top_t	                is array(NUM_FE_links-1 downto 0) of std_logic_vector(GBT_word_size-1 downto 0);
  type FE_valid_top_t                   is array(NUM_FE_links-1 downto 0) of std_logic;
  type FE_subdetector_type_t            is array(NUM_SOL40_links-1 downto 0) of std_logic_vector(7 downto 0);
  type FE_enables_array_t               is array(NUM_FE_links-1 downto 0) of std_logic_vector(NUM_FE_links-1 downto 0);
  type FE_delays_t                      is array(NUM_FE_links-1 downto 0) of time;
  constant delay_fe                     : FE_delays_t := (0 ns, 400 ns, 800 ns, 1200 ns, 1600 ns, 2000 ns, 2400 ns, 2800 ns, 3200 ns, 3600 ns, 4000 ns, 4400 ns, 4800 ns, 5200 ns, 5600 ns, 6000 ns, 6400 ns, 6800 ns, 7200 ns, 7600 ns, 8000 ns, 8400 ns, 8800 ns, 9200 ns);

------------------------------ Fiber mapping interface -----------------------------------------------------------------------
  constant GBT_word_size_for_tfc  : INTEGER := 80;

  constant GBT_word_size_tfc_or_acq_1  	: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(0))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(0)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_2		: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(1))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(1)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_3		: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(2))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(2)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_4		: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(3))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(3)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_5		: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(4))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(4)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_6		: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(5))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(5)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_7		: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(6))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(6)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_8		: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(7))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(7)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_9		: INTEGER := conv_integer(fiber_mapping_tfc_or_acq(8))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(8)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_10	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(9))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(9)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_11	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(10))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(10)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_12	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(11))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(11)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_13	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(12))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(12)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_14	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(13))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(13)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_15	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(14))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(14)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_16	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(15))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(15)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_17	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(16))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(16)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_18	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(17))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(17)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_19	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(18))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(18)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_20	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(19))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(19)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_21	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(20))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(20)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_22	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(21))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(21)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_23	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(22))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(22)))*GBT_word_size);
  constant GBT_word_size_tfc_or_acq_24	        : INTEGER := conv_integer(fiber_mapping_tfc_or_acq(23))*80 + (conv_integer(not(fiber_mapping_tfc_or_acq(23)))*GBT_word_size);



END Constant_Declaration;


