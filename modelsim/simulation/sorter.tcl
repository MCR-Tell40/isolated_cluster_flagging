vsim -novopt work.sorter

add wave -noupdate -divider Sorter\ Test

add wave -position end  sim:/sorter/clk
add wave -position end  sim:/sorter/rst
add wave -position end  sim:/sorter/en
add wave -position end  sim:/sorter/odd
add wave -position end  sim:/sorter/i_data
add wave -position end  sim:/sorter/s_data
add wave -position end  sim:/sorter/o_data

force -freeze sim:/sorter/clk 1 0, 0 {3125 ps} -r 6.25ns
force -freeze sim:/sorter/rst 1 0
force -freeze sim:/sorter/rst 0 6.5ns
force -freeze sim:/sorter/odd 0 8ns
force -freeze sim:/sorter/en 1 8ns

source ../gen_scripts/sorter_unsorted.tcl

run 40ns
