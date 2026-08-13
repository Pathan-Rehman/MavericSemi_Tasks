# Yosys logic synthesis for alu3_pipeline using the SkyWater sky130A PDK.
# Usage: yosys -c scripts/synth.tcl
#
# The standard-cell library is sky130_fd_sc_hd (typical corner: tt_025C_1v80).

yosys -import

set script_dir [file dirname [file normalize [info script]]]
set proj_dir   [file normalize [file join $script_dir ..]]
set out_dir    [file join $proj_dir output synth]
set rtl_file   [file join $proj_dir rtl alu3_pipeline.sv]

set liberty "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

file mkdir $out_dir

puts ""
puts "=================================================================="
puts " 1. READ TECHNOLOGY LIBRARY  (sky130_fd_sc_hd, tt_025C_1v80)"
puts "=================================================================="
read_liberty -lib $liberty

puts ""
puts "=================================================================="
puts " 2. READ RTL"
puts "=================================================================="
read_verilog -sv $rtl_file

puts ""
puts "=================================================================="
puts " 3. HIGH-LEVEL SYNTHESIS  ->  synth -top alu3_pipeline"
puts "=================================================================="
synth -top alu3_pipeline

puts ""
puts "=================================================================="
puts " 4. MAP FLIP-FLOPS  ->  dfflibmap -liberty"
puts "=================================================================="
dfflibmap -liberty $liberty

puts ""
puts "=================================================================="
puts " 5. MAP COMBINATIONAL LOGIC  ->  abc -liberty"
puts "=================================================================="
abc -liberty $liberty
opt_clean

puts ""
puts "=================================================================="
puts " 6. GATE-LEVEL STATISTICS  ->  stat -liberty"
puts "=================================================================="
stat -liberty $liberty

puts ""
puts "=================================================================="
puts " 7. CONSISTENCY CHECK  ->  check"
puts "=================================================================="
check

puts ""
puts "=================================================================="
puts " 8. WRITE GATE-LEVEL NETLIST"
puts "=================================================================="
write_verilog -noattr [file join $out_dir alu3_pipeline_synth.v]
write_json  [file join $out_dir alu3_pipeline.json]

puts ""
puts "Synthesis complete. Netlist written to: [file join $out_dir alu3_pipeline_synth.v]"