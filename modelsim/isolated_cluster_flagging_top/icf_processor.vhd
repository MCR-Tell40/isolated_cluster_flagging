--icf_processor.vhd
-- State machine to organise the running of the sorter and flagger using a counter
-- 	s0 (4 clk cycles): read in the four packets which make up the datatrain
--	s1 (119 clk cycles): sort spatially by column number
--	s2 (1 clk cycles): flag if sorting is complete
--	s3 (4 clk cycles): write out the four packets
-- Author D. Murray <donal.murray@cern.ch>
-- May 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.AMC40_pack.all;
use work.Constant_Declaration.all;
use work.detector_constant_declaration.all;
use work.GDP_pack.all;

entity icf_processor is
  port (
  i_Clock_160MHz        : in  std_logic;
  i_reset               : in  std_logic;

  i_enable              : in  std_logic;
  i_sppram_id           : in  natural range 0 to 15;
  i_sppram_id_dv        : in  std_logic;
  i_ram_counter         : in  std_logic_vector(sppram_w_seg_size - 1 downto 0);
  i_bus                 : in  std_logic_vector(383 downto 0);

  o_enable              : out std_logic;
  o_sppram_id           : out natural range 0 to 15;
  o_sppram_id_dv        : out std_logic;
  o_ram_counter         : out std_logic_vector(sppram_w_seg_size - 1 downto 0);
  o_bus                 : out std_logic_vector(511 downto 0)
);
end icf_processor;

architecture icf_proc_arch of icf_processor is
  -----------
  --signals--
  -----------
  --type spp_array is array 15 downto 0 of std_logic_vector(31 downto 0); -- put in AMC40_pack_p.vhd
  type state_machine is (s0, s1, s2, s3);

  signal s_en           : std_logic; 		-- sorter enable
  signal s_odd          : std_logic; 		-- odd/even or even/odd
  signal si_bus         : spp_array; 		-- input to sorter
  signal so_bus         : spp_array; 		-- output from sorter
  signal s_buffer       : spp_array; 		-- takes sorter output and feeds it back as input
  signal f_en           : std_logic; 		-- flagger enable
  signal fo_bus         : spp_array; 		-- output from flagger
  signal state          : state_machine; 	-- state of processor (state machine)
  signal c_en           : std_logic; 		-- counter enable
  signal co_value       : std_logic_vector(7 downto 0); -- value of counter

  -- signals to keep everything in sync
  signal s_enable       : std_logic_vector(3 downto 0);
  signal s_sppram_id_dv : std_logic_vector(3 downto 0);
  signal s_ram_counter  : t_ram_counter; 	-- defined in AMC40_pack_p.vhd
  signal s_sppram_id    : t_sppram_id;		-- defined in AMC40_pack_p.vhd

begin

  ICF_COUNTER: entity work.counter(count_arch)
  port map (
    i_Clock_160MHz,
    i_reset,
    c_en,
    co_value
  );

  ICF_SORTER: entity work.sorter(sort_arch)
  port map (
    i_Clock_160MHz,
    i_reset,
    s_en,
    s_odd,
    si_bus,
    so_bus
  );

  ICF_FLAGGER: entity work.flagger(flag_arch)
  port map (
    i_reset,
    i_Clock_160MHz,
    f_en,
    so_bus,
    fo_bus
  );

  -- assemble array of spps
  process(i_Clock_160MHz, i_reset, i_enable)
  begin
    if i_reset = '1' then
      -- reset
      o_enable       <= '0';
      o_sppram_id_dv <= '0';
      o_ram_counter  <= (others => '0');
      o_bus          <= (others => '0');
      c_en           <= '0';
      s_en           <= '0';
      f_en           <= '0';
      state          <= s0;
    elsif rising_edge(i_enable) then
      -- start the clock
      c_en           <= '1';
    elsif rising_edge(i_Clock_160MHz) and i_enable = '1' then
      if state = s0 then
	-- state 0 -- read in data and assemble the spp_array - 4 clk cycles
	if co_value = x"00" then
	  --co_count = x"00" - start of process
	  s_enable(0)       <= i_enable;
	  s_sppram_id_dv(0) <= i_sppram_id_dv;
	  s_ram_counter(0)  <= i_ram_counter;
	  s_sppram_id(0)    <= i_sppram_id;
	  si_bus(0)         <= "00000000" & i_bus(383 downto 360);
	  si_bus(1)         <= "00000000" & i_bus(359 downto 336);
	  si_bus(2)         <= "00000000" & i_bus(335 downto 312);
	  si_bus(3)         <= "00000000" & i_bus(311 downto 288);
	  si_bus(4)         <= "00000000" & i_bus(287 downto 264);
	  si_bus(5)         <= "00000000" & i_bus(263 downto 240);
	  si_bus(6)         <= "00000000" & i_bus(239 downto 216);
	  si_bus(7)         <= "00000000" & i_bus(215 downto 192);
	  si_bus(8)         <= "00000000" & i_bus(191 downto 168);
	  si_bus(9)         <= "00000000" & i_bus(167 downto 144);
	  si_bus(10)        <= "00000000" & i_bus(143 downto 120);
	  si_bus(11)        <= "00000000" & i_bus(119 downto 96);
	  si_bus(12)        <= "00000000" & i_bus(95 downto 72);
	  si_bus(13)        <= "00000000" & i_bus(71 downto 48);
	  si_bus(14)        <= "00000000" & i_bus(47 downto 24);
	  si_bus(15)        <= "00000000" & i_bus(23 downto 0);
	elsif co_value = x"01" then
	  s_enable(1)       <= i_enable;
	  s_sppram_id_dv(1) <= i_sppram_id_dv;
	  s_ram_counter(1)  <= i_ram_counter;
	  s_sppram_id(1)    <= i_sppram_id;
	  si_bus(16)        <= "00000000" & i_bus(383 downto 360);
	  si_bus(17)        <= "00000000" & i_bus(359 downto 336);
	  si_bus(18)        <= "00000000" & i_bus(335 downto 312);
	  si_bus(19)        <= "00000000" & i_bus(311 downto 288);
	  si_bus(20)        <= "00000000" & i_bus(287 downto 264);
	  si_bus(21)        <= "00000000" & i_bus(263 downto 240);
	  si_bus(22)        <= "00000000" & i_bus(239 downto 216);
	  si_bus(23)        <= "00000000" & i_bus(215 downto 192);
	  si_bus(24)        <= "00000000" & i_bus(191 downto 168);
	  si_bus(25)        <= "00000000" & i_bus(167 downto 144);
	  si_bus(26)        <= "00000000" & i_bus(143 downto 120);
	  si_bus(27)        <= "00000000" & i_bus(119 downto 96);
	  si_bus(28)        <= "00000000" & i_bus(95 downto 72);
	  si_bus(29)        <= "00000000" & i_bus(71 downto 48);
	  si_bus(30)        <= "00000000" & i_bus(47 downto 24);
	  si_bus(31)        <= "00000000" & i_bus(23 downto 0);
	elsif co_value = x"02" then
	  s_enable(2)       <= i_enable;
	  s_sppram_id_dv(2) <= i_sppram_id_dv;
	  s_ram_counter(2)  <= i_ram_counter;
	  s_sppram_id(2)    <= i_sppram_id;
	  si_bus(32)        <= "00000000" & i_bus(383 downto 360);
	  si_bus(33)        <= "00000000" & i_bus(359 downto 336);
	  si_bus(34)        <= "00000000" & i_bus(335 downto 312);
	  si_bus(35)        <= "00000000" & i_bus(311 downto 288);
	  si_bus(36)        <= "00000000" & i_bus(287 downto 264);
	  si_bus(37)        <= "00000000" & i_bus(263 downto 240);
	  si_bus(38)        <= "00000000" & i_bus(239 downto 216);
	  si_bus(39)        <= "00000000" & i_bus(215 downto 192);
	  si_bus(40)        <= "00000000" & i_bus(191 downto 168);
	  si_bus(41)        <= "00000000" & i_bus(167 downto 144);
	  si_bus(42)        <= "00000000" & i_bus(143 downto 120);
	  si_bus(43)        <= "00000000" & i_bus(119 downto 96);
	  si_bus(44)        <= "00000000" & i_bus(95 downto 72);
	  si_bus(45)        <= "00000000" & i_bus(71 downto 48);
	  si_bus(46)        <= "00000000" & i_bus(47 downto 24);
	  si_bus(47)        <= "00000000" & i_bus(23 downto 0);
	elsif co_value = x"03" then
	  s_enable(3)       <= i_enable;
	  s_sppram_id_dv(3) <= i_sppram_id_dv;
	  s_ram_counter(3)  <= i_ram_counter;
	  s_sppram_id(3)    <= i_sppram_id;
	  si_bus(48)        <= "00000000" & i_bus(383 downto 360);
	  si_bus(49)        <= "00000000" & i_bus(359 downto 336);
	  si_bus(50)        <= "00000000" & i_bus(335 downto 312);
	  si_bus(51)        <= "00000000" & i_bus(311 downto 288);
	  si_bus(52)        <= "00000000" & i_bus(287 downto 264);
	  si_bus(53)        <= "00000000" & i_bus(263 downto 240);
	  si_bus(54)        <= "00000000" & i_bus(239 downto 216);
	  si_bus(55)        <= "00000000" & i_bus(215 downto 192);
	  si_bus(56)        <= "00000000" & i_bus(191 downto 168);
	  si_bus(57)        <= "00000000" & i_bus(167 downto 144);
	  si_bus(58)        <= "00000000" & i_bus(143 downto 120);
	  si_bus(59)        <= "00000000" & i_bus(119 downto 96);
	  si_bus(60)        <= "00000000" & i_bus(95 downto 72);
	  si_bus(61)        <= "00000000" & i_bus(71 downto 48);
	  si_bus(62)        <= "00000000" & i_bus(47 downto 24);
	  si_bus(63)        <= "00000000" & i_bus(23 downto 0);
	  -- all 4 frames have been read in, go to state 1
	  state             <= s1;
	  s_en              <= '1';
	  s_odd             <= '1';
	end if;
      elsif state = s1 then
	-- state 1 - sort (120 clk cycles)
	-- enable sorter
	if co_value = x"04" then
	  s_odd  <= '0';
	  s_en   <= '1';
	  so_bus <= si_bus;
	elsif co_value = x"05" then
	  -- second cycle of sorting, redirect output to input
	  s_odd  <= '1';
	  si_bus <= so_bus;
	elsif to_integer(unsigned(co_value)) mod 2 = 0 then
	  -- give the sorter data with even flag
	  --even pass
	  so_bus <= si_bus;
	  s_odd  <= '0';
	else
	  -- give the sorter data with odd flag
	  --odd pass
	  so_bus <= si_bus;
	  s_odd  <= '1';
	end if;

	if co_value = x"79" then
	  -- wait 119 clock cycles for it to return the sorted data then change to next state and get ready to flag
	  s_en  <= '0';
	  f_en  <= '1';
	  state <= s2;
	end if;
      elsif state = s2 then
	-- state 2 - flag
	if to_integer(unsigned(i_ram_counter)) > MAX_COUNT then
	  state <= s3;
	elsif state = s3 then
	  -- disassemble array of spps as they are written out
	  f_en  <= '0';
	  if co_value = x"7B" then
	    --start assembling o_bus at clk 124
	    o_enable       <= s_enable(0);
	    o_sppram_id_dv <= s_sppram_id_dv(0);
	    o_ram_counter  <= s_ram_counter(0);
	    o_sppram_id    <= s_sppram_id(0);
	    o_bus          <= fo_bus(0)&
			      fo_bus(1)&
			      fo_bus(2)&
			      fo_bus(3)&
			      fo_bus(4)&
			      fo_bus(5)&
			      fo_bus(6)&
			      fo_bus(7)&
			      fo_bus(8)&
			      fo_bus(9)&
			      fo_bus(10)&
			      fo_bus(11)&
			      fo_bus(12)&
			      fo_bus(13)&
			      fo_bus(14)&
			      fo_bus(15);
	  elsif co_value = x"7D" then
	    o_enable       <= s_enable(1);
	    o_sppram_id_dv <= s_sppram_id_dv(1);
	    o_ram_counter  <= s_ram_counter(1);
	    o_sppram_id    <= s_sppram_id(1);
	    o_bus          <= fo_bus(16)&
			      fo_bus(17)&
			      fo_bus(18)&
			      fo_bus(19)&
			      fo_bus(20)&
			      fo_bus(21)&
			      fo_bus(22)&
			      fo_bus(23)&
			      fo_bus(24)&
			      fo_bus(25)&
			      fo_bus(26)&
			      fo_bus(27)&
			      fo_bus(28)&
			      fo_bus(29)&
			      fo_bus(30)&
			      fo_bus(31);
	  elsif co_value = x"7E" then
	    o_enable       <= s_enable(2);
	    o_sppram_id_dv <= s_sppram_id_dv(2);
	    o_ram_counter  <= s_ram_counter(2);
	    o_sppram_id    <= s_sppram_id(2);
	    o_bus          <= fo_bus(32)&
			      fo_bus(33)&
			      fo_bus(34)&
			      fo_bus(35)&
			      fo_bus(36)&
			      fo_bus(37)&
			      fo_bus(38)&
			      fo_bus(39)&
			      fo_bus(40)&
			      fo_bus(41)&
			      fo_bus(42)&
			      fo_bus(43)&
			      fo_bus(44)&
			      fo_bus(45)&
			      fo_bus(46)&
			      fo_bus(47);
	  elsif co_value = x"7F" then
	    o_enable       <= s_enable(3);
	    o_sppram_id_dv <= s_sppram_id_dv(3);
	    o_ram_counter  <= s_ram_counter(3);
	    o_sppram_id    <= s_sppram_id(3);
	    o_bus          <= fo_bus(48)&
			      fo_bus(49)&
			      fo_bus(50)&
			      fo_bus(51)&
			      fo_bus(52)&
			      fo_bus(53)&
			      fo_bus(54)&
			      fo_bus(55)&
			      fo_bus(56)&
			      fo_bus(57)&
			      fo_bus(58)&
			      fo_bus(59)&
			      fo_bus(60)&
			      fo_bus(61)&
			      fo_bus(62)&
			      fo_bus(63);
	    -- change to state 0 ready for clk 128
	    state          <= s0;
	    c_en           <= '0';
	  end if;
	end if;
      end if;
      s_buffer <= so_bus; -- redirect output of sorter to buffer
    end if;
  end process;
end icf_proc_arch;
