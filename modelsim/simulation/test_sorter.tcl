vsim -novopt work.sorter
config wave -signalnamewidth 1

add wave -noupdate -divider Testing\ Sorter

add wave -position end sim:/sorter/clk
add wave -position end sim:/sorter/rst
add wave -position end sim:/sorter/parity
add wave -position end sim:/sorter/rd_data
add wave -position end sim:/sorter/inter_reg
add wave -position end sim:/sorter/wr_data

for {set i 0}  {$i < 128} {incr i} {
	set val [expr {$i *256 * 256 * 256 + $i *256 * 256 + $i * 256 + $i}]
	set hex [format %08x $val]
	mem load -filltype value -filldata $hex -fillradix hexadecimal /sorter/rd_data($i)
}

force -freeze sim:/sorter/clk 1 0, 0 {3125 ps} -r 6.25ns
force -freeze sim:/sorter/rst 1 1
force -freeze sim:/sorter/rst 0 5ns

when {parity'event} {
	for {set i 0}  {$i < 128} {incr i} {
		set /sorter/wr_data($i) /sorter/rd_data($i)
	}
}

force -freeze sim:/sorter/parity 1 0, 0 {20ns} -r 40ns

run 100
