#!/usr/bin/env tclsh
# Compile + simulate the 3-stage pipeline datapath (iverilog + vvp), then open gtkwave.
# Usage: tclsh scripts/sim.tcl

set script_dir [file dirname [file normalize [info script]]]
set proj_dir   [file normalize [file join $script_dir ..]]
set sim_dir    [file join $proj_dir output sim]
set tb_dir     [file join $proj_dir sim]
set rtl_file   [file join $proj_dir rtl alu3_pipeline.sv]
set tb_file    [file join $tb_dir tb_alu3_pipeline.sv]

file mkdir $sim_dir
cd $sim_dir

puts "=================================================================="
puts " 1. COMPILATION  ->  iverilog -g2012"
puts "=================================================================="
puts "iverilog -g2012 -o tb_alu3_pipeline.vvp $rtl_file $tb_file"
exec iverilog -g2012 -o tb_alu3_pipeline.vvp $rtl_file $tb_file >@stdout 2>@stdout

puts ""
puts "=================================================================="
puts " 2. SIMULATION  ->  vvp"
puts "=================================================================="
puts "vvp tb_alu3_pipeline.vvp"
exec vvp tb_alu3_pipeline.vvp >@stdout

puts ""
puts "=================================================================="
puts " 3. WAVEFORM VIEWER  ->  gtkwave tb_alu3_pipeline.vcd"
puts "=================================================================="
if {[info exists env(DISPLAY)] && [string length $env(DISPLAY)] > 0} {
    puts "gtkwave tb_alu3_pipeline.vcd"
    exec sh -c "gtkwave tb_alu3_pipeline.vcd > /dev/null 2>&1 &"
} else {
    puts "No DISPLAY set - waveform saved in tb_alu3_pipeline.vcd"
}

puts ""
puts "Simulation complete."