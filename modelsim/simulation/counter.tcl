add wave -noupdate -divider Test\ Counter

add wave -position end  sim:/counter/clk
add wave -position end  sim:/counter/en
add wave -position end  sim:/counter/rst
add wave -position end  sim:/counter/s_count
add wave -position end  sim:/counter/o_count

force -freeze sim:/counter/clk 1 0, 0 {3125 ps} -r 6.25ns
force -freeze sim:/counter/rst 1 0
force -freeze sim:/counter/rst 0 6.5ns

force -freeze sim:/counter/en 1 10ns

force -freeze sim:/counter/rst 1 60ns

run 100
