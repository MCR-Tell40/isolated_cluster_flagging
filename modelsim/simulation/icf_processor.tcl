vsim -novopt work.icf_processor

add wave -noupdate -divider ICF\ Processor\ Test


# inputs
add wave -noupdate -divider Inputs
add wave -position end  sim:/icf_processor/i_Clock_160MHz
add wave -position end  sim:/icf_processor/i_reset
add wave -position end  sim:/icf_processor/i_bus
add wave -position end  sim:/icf_processor/i_enable
add wave -position end  sim:/icf_processor/i_ram_counter
add wave -position end  sim:/icf_processor/i_sppram_id_dv


# outputs
add wave -noupdate -divider Outputs
add wave -position end  sim:/icf_processor/o_bus
add wave -position end  sim:/icf_processor/o_enable
add wave -position end  sim:/icf_processor/o_ram_counter
add wave -position end  sim:/icf_processor/o_sppram_id_dv


# signals
add wave -noupdate -divider Signals
add wave -position end  sim:/icf_processor/state

add wave -noupdate -divider Counter
add wave -position end  sim:/icf_processor/ci_enable
add wave -position end  sim:/icf_processor/co_value

add wave -noupdate -divider Sorter
add wave -position end  sim:/icf_processor/s_en
add wave -position end  sim:/icf_processor/s_odd
add wave -position end  sim:/icf_processor/si_bus
add wave -position end  sim:/icf_processor/so_bus

add wave -noupdate -divider flagger
add wave -position end  sim:/icf_processor/f_en
add wave -position end  sim:/icf_processor/fo_bus


# start clock
force -freeze sim:/icf_processor/i_Clock_160MHz 1 0, 0 {3125 ps} -r 6.25ns

# reset
force -freeze sim:/icf_processor/i_reset 1 0
force -freeze sim:/icf_processor/i_reset 0 1

# enable and load first ram
force -freeze sim:/icf_processor/i_enable 1 1
source ../gen_scripts/sorter_unsorted.tcl

run 40ns
