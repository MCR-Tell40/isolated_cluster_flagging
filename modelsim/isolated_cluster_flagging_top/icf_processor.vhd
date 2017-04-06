library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.AMC40_pack.all;
use work.Constant_Declaration.all;
use work.detector_constant_declaration.all;

library work;
use work.GDP_pack.all;

entity icf_processor is
    port (
        i_Clock_160MHz      : in  std_logic;
        i_reset             : in  std_logic;

        i_enable            : in std_logic;
        i_sppram_id_dv 	    : in std_logic;
        i_ram_counter       : in std_logic_vector(sppram_w_seg_size - 1 downto 0);
        i_bus               : in std_logic_vector(511 downto 0)

        o_enable            : out std_logic;
        o_sppram_id_dv 	    : out std_logic;
        o_ram_counter       : out std_logic_vector(sppram_w_seg_size - 1 downto 0)
        o_bus               : out std_logic_vector(511 downto 0)
    );
end icf_processor;

architecture a of icf_processor is
    --------------
    --components--
    --------------
    component counter is
        port(
            clk             : in 	std_logic;
            rst             : in 	std_logic;
            en	            : in 	std_logic;
	        count 			: out	std_logic_vector(7 downto 0)
        );
    end component;

    component sorter is
		port(
            clk             : in	std_logic;
            rst             : in	std_logic;
      	    odd         	: in	std_logic; -- 1 odd/even 0 even/odd
      	    i_data       	: in	spp_array;
      	    o_data			: in	spp_array
        );
    end component;

    component flagger is
    	port(
    		rst 			: in	std_logic;
       		clk				: in 	std_logic;
       		i_data			: in 	spp_array;
       		o_data			: out 	spp_array
    	);
    end component;

    -----------
    --signals--
    -----------
    type spp_array is array 15 downto 0 of std_logic_vector(31 downto 0); -- put in a package file
    type state_machine is (s0, s1, s2, s3);

    signal si_bus           : spp_array;
    signal so_bus           : spp_array;
    signal state            : state_machine; -- state of processor (state machine)
    signal ci_enable        : std_logic; -- counter enable
    signal co_value         : std_logic_vector(7 downto 0); -- TODO check this if i need this many bits (xFF) -  do i not only need 80 bits as this is the max nr of clock cycles for each data processor?
    signal sorter_odd       : std_logic; -- odd/even or even/odd

begin

    COUNTER: counter
    port map(
        i_Clock_160MHz,
        i_reset,
        ci_enable,
        co_value
    );

    SORTER: sorter
    port map(
        i_Clock_160MHz,
        i_reset,
        sorter_odd,
        si_bus,
        so_bus
    );

    -- assemble array of spps
    process(i_Clock_160MHz, i_reset, i_enable)
    begin
        if i_reset = 1 then
            -- reset
            count_enable    = 0;
            state           <= s0;
        elsif rising_edge(i_Clock_160MHz) and i_enable = 1 then
            if state = s0 then
                -- state 0 -- read in data and assemble the spp_array
                si_bus(0)       <= i_infl_bus(511 downto 480) &
                si_bus(1)       <= i_infl_bus(479 downto 448) &
                si_bus(2)       <= i_infl_bus(447 downto 416) &
                si_bus(3)       <= i_infl_bus(415 downto 384) &
                si_bus(4)       <= i_infl_bus(383 downto 352) &
                si_bus(5)       <= i_infl_bus(351 downto 320) &
                si_bus(6)       <= i_infl_bus(319 downto 288) &
                si_bus(7)       <= i_infl_bus(287 downto 256) &
                si_bus(8)       <= i_infl_bus(255 downto 224) &
                si_bus(9)       <= i_infl_bus(223 downto 192) &
                si_bus(10)      <= i_infl_bus(191 downto 160) &
                si_bus(11)      <= i_infl_bus(159 downto 128) &
                si_bus(12)      <= i_infl_bus(127 downto 96) &
                si_bus(13)      <= i_infl_bus(95 downto 64) &
                si_bus(14)      <= i_infl_bus(63 downto 32) &
                si_bus(15)      <= i_infl_bus(31 downto 0);

                if count_enable = 0 then
                    -- start the clock
                    count_enable <= 1;
                elsif count = 3 then
                    -- all 4 frames have been read in, go to state 1
                    state <= 1;
                end if;
            elsif state = s1 then
                -- state 1 - sort
                -- pass data to the sorter and start counter
                if clock_count = 80 -
            elsif state = s2 then
                -- state 2 - flag

            -- disassemble array of spps as they are written out
            o_bus           <= so_bus(0) &
                               so_bus(1) &
                               so_bus(2) &
                               so_bus(3) &
                               so_bus(4) &
                               so_bus(5) &
                               so_bus(6) &
                               so_bus(7) &
                               so_bus(8) &
                               so_bus(9) &
                               so_bus(10) &
                               so_bus(11) &
                               so_bus(12) &
                               so_bus(13) &
                               so_bus(14) &
                               so_bus(15);
        end if;
    end process;
end a;
