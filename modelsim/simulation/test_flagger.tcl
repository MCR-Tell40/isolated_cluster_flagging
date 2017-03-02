vsim -novopt work.counter
config wave -signalnamewidth 1

add wave -noupdate -divider Testing\ Flagger

add wave -position end  sim:/flagger/clk
add wave -position end  sim:/flagger/rd_data
add wave -position end  sim:/flagger/rst
add wave -position end  sim:/flagger/wr_data

force -freeze sim:/flagger/clk 1 0, 0 {3125 ps} -r 6.25ns
force -freeze sim:/flagger/rst 1 0
force -freeze sim:/flagger/rst 0 6.5ns

force -freeze sim:/flagger/rst 1 60ns

run 100
