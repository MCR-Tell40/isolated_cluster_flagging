vsim -novopt work.isolated_cluster_flagging_top

#title
add wave -noupdate -divider ICF\ Top\ Test

#I/O
add wave -noupdate -divider I/O
add wave -position end  sim:/isolated_cluster_flagging_top/i_Clock_160MHz
add wave -position end  sim:/isolated_cluster_flagging_top/i_reset
add wave -position end  sim:/isolated_cluster_flagging_top/i_bus
add wave -position end  sim:/isolated_cluster_flagging_top/o_bus

#Passthrough
add wave -noupdate -divider Passthrough
add wave -position end  sim:/isolated_cluster_flagging_top/i_ram_counter
add wave -position end  sim:/isolated_cluster_flagging_top/i_sppram_id
add wave -position end  sim:/isolated_cluster_flagging_top/i_sppram_id_dv
add wave -position end  sim:/isolated_cluster_flagging_top/o_ram_counter
add wave -position end  sim:/isolated_cluster_flagging_top/o_sppram_id
add wave -position end  sim:/isolated_cluster_flagging_top/o_sppram_id_dv

#Signals
add wave -noupdate -divider Signals

#Counter
add wave -noupdate -divider Counter
add wave -position end  sim:/isolated_cluster_flagging_top/c_en
add wave -position end  sim:/isolated_cluster_flagging_top/co_value

#Data processors
add wave -noupdate -divider Data\ Processors
add wave -position end  sim:/isolated_cluster_flagging_top/dp_i_enable
add wave -position end  sim:/isolated_cluster_flagging_top/dp_o_enable
add wave -position end  sim:/isolated_cluster_flagging_top/s_sppram_id



# start clock
force -freeze sim:/isolated_cluster_flagging_top/i_Clock_160MHz 1 0, 0 {2000 ps} -r 4000ps

# reset
force -freeze sim:/isolated_cluster_flagging_top/i_reset 1 0
force -freeze sim:/isolated_cluster_flagging_top/i_reset 0 1

# set number of SPPs to max (199)
force -freeze sim:/isolated_cluster_flagging_top/i_ram_counter "011000111" 0

# set i_sppram_id_dv to 0
force -freeze sim:/isolated_cluster_flagging_top/i_sppram_id_dv 0 0

# load 383 bit trains, 1 per clock cycle
source ../gen_scripts/top_raw.tcl

run 10000
