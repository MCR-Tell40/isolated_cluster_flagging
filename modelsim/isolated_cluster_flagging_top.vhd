--isolated_cluster_flagging_top.vhd
-- Drop in isolated cluster flagging (ICF) module which can be added or removed from post router
-- Spatially sorts SPPs and checks whether there are any with no hits in neighbouring columns
-- Flags these SPPs for bypass to decrease the load on the CPU during offline event reconstruction
-- Replaces inflactionary_block and interfaces with the inputs of edge detectors
--
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

entity isolated_cluster_flagging_top is
    	port (
        	--inputs
        	-- post_router_top interface
        	i_Clock_160MHz      	: in  std_logic; -- clk
        	i_reset             	: in  std_logic; -- reset or bxid delay reset
	
        	i_sppram_id         	: in natural range 0 to 15; -- id of the ram giving the data
        	i_sppram_id_dv 	    	: in std_logic;
        	i_ram_counter       	: in std_logic_vector(sppram_w_seg_size - 1 downto 0);
		i_bus			: in std_logic_vector(383 downto 0);

        	--outputs
        	-- edge_detector interface
        	o_sppram_id         	: out natural range 0 to 15;
        	o_sppram_id_dv 	    	: out std_logic;
        	o_ram_counter       	: out std_logic_vector(sppram_w_seg_size - 1 downto 0);
        	-- output_fifo interface
        	o_bus          		: out std_logic_vector(511 downto 0)
	);
end isolated_cluster_flagging_top;

architecture a of isolated_cluster_flagging_top is

    component icf_processor is
        port (
            i_Clock_160MHz      : in  std_logic;
            i_reset             : in  std_logic;

            i_enable            : in std_logic;
            i_sppram_id_dv 	: in std_logic;
            i_ram_counter       : in std_logic_vector(sppram_w_seg_size - 1 downto 0);
            i_bus               : in std_logic_vector(383 downto 0);
            i_sppram_id         : in natural range 0 to 15;

            o_sppram_id         : out natural range 0 to 15;
            o_enable            : out std_logic;
            o_sppram_id_dv 	: out std_logic;
            o_ram_counter       : out std_logic_vector(sppram_w_seg_size - 1 downto 0);
            o_bus               : out std_logic_vector(511 downto 0)
        );
    end component icf_processor;

    component counter is
        port(
            clk             	: in 	std_logic;
            rst             	: in 	std_logic;
            en	            	: in 	std_logic;
    	    o_count 		: out	std_logic_vector(7 downto 0)
        );
    end component;

    	-- SIGNALS
    	   signal dp_i_enable          : std_logic_vector(31 downto 0);
    	   signal dp_o_enable          : std_logic_vector(31 downto 0);
	   signal s_sppram_id          : t_sppram_id;
           signal c_en                 : std_logic;
           signal co_value             : std_logic_vector(7 downto 0);
           signal processing           : std_logic;

begin
    --generate 16 processors -- their enable determines when they should interact with the shared pipes
    	GEN_ICF_PROCESSOR :
	for i in 0 to 31 generate
	ICF_PROCESSORx: icf_processor
		port map(
        		i_Clock_160MHz,
            		i_reset,
			dp_i_enable(i),
			i_sppram_id_dv,
			i_ram_counter,
            		i_bus, -- shared input data pipe
            		i_sppram_id,
            		s_sppram_id(i),
			dp_o_enable(i),
			o_sppram_id_dv,
			o_ram_counter,
    			o_bus -- shared output data pipe
        	);
	end generate;

    	ICF_COUNTER: counter
    	port map(
    	    i_Clock_160MHz,
    	    i_reset,
    	    c_en,
    	    co_value
    	);

    --main control process
    process(i_Clock_160MHz, i_reset)
    begin
        if i_reset = '1' then
            --o_sppram_id     <= 0;
            o_sppram_id_dv  <= '0';
            o_ram_counter   <= (others => '0');
            o_bus <= (others => '0');
            processing      <= '0';
        elsif processing = '0' then
            --start the clock
            c_en <= '0';
        elsif rising_edge(i_Clock_160MHz) then
		if co_value = x"00" then
			--enable processor:0
			dp_i_enable(0) <= '1';
			--disable processor:1
			dp_i_enable(1) <= '0';
		elsif co_value = x"04" then
			--enable processor:1
			dp_i_enable(1) <= '1';
			--disable processor:2
			dp_i_enable(2) <= '0';
		elsif co_value = x"08" then
			--enable processor:2
			dp_i_enable(2) <= '1';
			--disable processor:3
			dp_i_enable(3) <= '0';
		elsif co_value = x"0C" then
			--enable processor:3
			dp_i_enable(3) <= '1';
			--disable processor:4
			dp_i_enable(4) <= '0';
		elsif co_value = x"10" then
			--enable processor:4
			dp_i_enable(4) <= '1';
			--disable processor:5
			dp_i_enable(5) <= '0';
		elsif co_value = x"14" then
			--enable processor:5
			dp_i_enable(5) <= '1';
			--disable processor:6
			dp_i_enable(6) <= '0';
		elsif co_value = x"18" then
			--enable processor:6
			dp_i_enable(6) <= '1';
			--disable processor:7
			dp_i_enable(7) <= '0';
		elsif co_value = x"1C" then
			--enable processor:7
			dp_i_enable(7) <= '1';
			--disable processor:8
			dp_i_enable(8) <= '0';
		elsif co_value = x"20" then
			--enable processor:8
			dp_i_enable(8) <= '1';
			--disable processor:9
			dp_i_enable(9) <= '0';
		elsif co_value = x"24" then
			--enable processor:9
			dp_i_enable(9) <= '1';
			--disable processor:10
			dp_i_enable(10) <= '0';
		elsif co_value = x"28" then
			--enable processor:10
			dp_i_enable(10) <= '1';
			--disable processor:11
			dp_i_enable(11) <= '0';
		elsif co_value = x"2C" then
			--enable processor:11
			dp_i_enable(11) <= '1';
			--disable processor:12
			dp_i_enable(12) <= '0';
		elsif co_value = x"30" then
			--enable processor:12
			dp_i_enable(12) <= '1';
			--disable processor:13
			dp_i_enable(13) <= '0';
		elsif co_value = x"34" then
			--enable processor:13
			dp_i_enable(13) <= '1';
			--disable processor:14
			dp_i_enable(14) <= '0';
		elsif co_value = x"38" then
			--enable processor:14
			dp_i_enable(14) <= '1';
			--disable processor:15
			dp_i_enable(15) <= '0';
		elsif co_value = x"3C" then
			--enable processor:15
			dp_i_enable(15) <= '1';
			--disable processor:16
			dp_i_enable(16) <= '0';
		elsif co_value = x"40" then
			--enable processor:16
			dp_i_enable(16) <= '1';
			--disable processor:17
			dp_i_enable(17) <= '0';
		elsif co_value = x"44" then
			--enable processor:17
			dp_i_enable(17) <= '1';
			--disable processor:18
			dp_i_enable(18) <= '0';
		elsif co_value = x"48" then
			--enable processor:18
			dp_i_enable(18) <= '1';
			--disable processor:19
			dp_i_enable(19) <= '0';
		elsif co_value = x"4C" then
			--enable processor:19
			dp_i_enable(19) <= '1';
			--disable processor:20
			dp_i_enable(20) <= '0';
		elsif co_value = x"50" then
			--enable processor:20
			dp_i_enable(20) <= '1';
			--disable processor:21
			dp_i_enable(21) <= '0';
		elsif co_value = x"54" then
			--enable processor:21
			dp_i_enable(21) <= '1';
			--disable processor:22
			dp_i_enable(22) <= '0';
		elsif co_value = x"58" then
			--enable processor:22
			dp_i_enable(22) <= '1';
			--disable processor:23
			dp_i_enable(23) <= '0';
		elsif co_value = x"5C" then
			--enable processor:23
			dp_i_enable(23) <= '1';
			--disable processor:24
			dp_i_enable(24) <= '0';
		elsif co_value = x"60" then
			--enable processor:24
			dp_i_enable(24) <= '1';
			--disable processor:25
			dp_i_enable(25) <= '0';
		elsif co_value = x"64" then
			--enable processor:25
			dp_i_enable(25) <= '1';
			--disable processor:26
			dp_i_enable(26) <= '0';
		elsif co_value = x"68" then
			--enable processor:26
			dp_i_enable(26) <= '1';
			--disable processor:27
			dp_i_enable(27) <= '0';
		elsif co_value = x"6C" then
			--enable processor:27
			dp_i_enable(27) <= '1';
			--disable processor:28
			dp_i_enable(28) <= '0';
		elsif co_value = x"70" then
			--enable processor:28
			dp_i_enable(28) <= '1';
			--disable processor:29
			dp_i_enable(29) <= '0';
		elsif co_value = x"74" then
			--enable processor:29
			dp_i_enable(29) <= '1';
			--disable processor:30
			dp_i_enable(30) <= '0';
		elsif co_value = x"78" then
			--enable processor:30
			dp_i_enable(30) <= '1';
			--disable processor:31
			dp_i_enable(31) <= '0';
		elsif co_value = x"7C" then
			--enable processor:31
			dp_i_enable(31) <= '1';
			--disable processor:0
			dp_i_enable(0) <= '0';
			c_en <= '0';
		end if;
--		--passthrough stream -- just inflate i_bus by prepending 8 zeroes
--		o_sppram_id     	<= i_sppram_id;
--    		o_sppram_id_dv  	<= i_sppram_id_dv;
--    		o_ram_counter   	<= i_ram_counter;
--    		o_bus		    	<= "00000000" & i_bus(383 downto 360) &
--		             		"00000000" & i_bus(359 downto 336) &
--	        	       		"00000000" & i_bus(335 downto 312) &
--	        	       		"00000000" & i_bus(311 downto 288) &
--	               	 		"00000000" & i_bus(287 downto 264) &
--	               	 		"00000000" & i_bus(263 downto 240) &
--	               	 		"00000000" & i_bus(239 downto 216) &
--	               	 		"00000000" & i_bus(215 downto 192) &
--	               	 		"00000000" & i_bus(191 downto 168) &
--	               	 		"00000000" & i_bus(167 downto 144) &
--	               	 		"00000000" & i_bus(143 downto 120) &
--	               	 		"00000000" & i_bus(119 downto 96)  &
--	               	 		"00000000" & i_bus(95 downto 72)   &
--	               	 		"00000000" & i_bus(71 downto 48)   &
--	               	 		"00000000" & i_bus(47 downto 24)   &
--	               	 		"00000000" & i_bus(23 downto 0);
--    		----------------------

        end if;
    end process;
end a;
