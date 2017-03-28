

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.detector_constant_declaration.all;	-- constants file
use work.isolated_clusters_package.all;		-- custom type definitions

entity mep_fifo is
	port (
		clk					: IN	std_logic;
		rst					: IN	std_logic;
		empty				: OUT	std_logic;

		-- active controller
		rd_en				: IN	std_logic;
		rd_data				: IN	std_logic_vector(BCID_WIDTH - 1 downto 0);

		-- bypass controller
		wr_en				: IN	std_logic;
		wr_data				: OUT	std_logic_vector(BCID_WIDTH - 1 downto 0));
end mep_fifo;

architecture fifo of mep_fifo is
	signal data_store		:		fifo_memory;
	begin
	process(clk, rst)
	begin
		if rst = '1' then
			-- reset fifo
		elsif rising_edge(clk) then
			-- check whether read or write has been requested
			if rd_en = '1' then
				-- read in from active controller
				data_store(1) 	<= rd_data;
			end if;

			if wr_en = '1' then
				-- write out to bypass controller
				wr_data 	<= data_store(1);
			end if;
		end if;
	end process;
end fifo;
