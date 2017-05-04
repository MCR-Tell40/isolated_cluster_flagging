vsim -novopt work.flagger

add wave -noupdate -divider Flagger\ Test

add wave -position end  sim:/flagger/clk
add wave -position end  sim:/flagger/rst
add wave -position end  sim:/flagger/en
add wave -position end  sim:/flagger/i_data
add wave -position end  sim:/flagger/s_data
add wave -position end  sim:/flagger/o_data

force -freeze sim:/flagger/clk 1 0, 0 {3125 ps} -r 6.25ns
force -freeze sim:/flagger/rst 1 0
force -freeze sim:/flagger/rst 0 6.5ns
force -freeze sim:/flagger/en 1 6.5ns

source ../gen_scripts/flagger_i_data.tcl

run 300
