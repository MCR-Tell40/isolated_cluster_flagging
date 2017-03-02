vsim -novopt work.sorter
config wave -signalnamewidth 1

add wave -noupdate -divider Testing\ Sorter

add wave -position end sim:/sorter/clk
add wave -position end sim:/sorter/rst
add wave -position end sim:/sorter/parity
add wave -position end sim:/sorter/rd_data
add wave -position end sim:/sorter/wr_data

force -freeze sim:/sorter/clk 1 0, 0 {3125 ps} -r 6.25ns
force -freeze sim:/sorter/rst 1 1
force -freeze sim:/sorter/rst 0 6.5ns

force -freeze sim:/sorter/rst 1 60ns

run 100
