# OpenSTA static timing analysis (setup + hold) for alu3_pipeline at 100 MHz.
# Usage: sta -tcl scripts/sta.tcl
#
# Analyzes the synthesized netlist (synth/alu3_pipeline_synth.v) against the
# sky130A sky130_fd_sc_hd liberty (tt_025C_1v80) with a 10 ns clock.

set script_dir [file dirname [file normalize [info script]]]
set proj_dir   [file normalize [file join $script_dir ..]]
set out_dir    [file join $proj_dir output sta]
set synth_dir  [file join $proj_dir output synth]

set liberty "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set netlist  [file join $synth_dir alu3_pipeline_synth.v]
set netlist_sta [file join $out_dir alu3_pipeline_sta.v]

file mkdir $out_dir

puts ""
puts "=================================================================="
puts " 1. READ LIBERTY + NETLIST  (sky130_fd_sc_hd, tt_025C_1v80)"
puts "=================================================================="
read_liberty $liberty

puts "Preparing netlist for OpenSTA parser (stripping 'signed' keywords):"
puts "  sed 's/signed //g' $netlist > $netlist_sta"
exec sed -e {s/signed //g} $netlist > $netlist_sta
read_verilog $netlist_sta
link_design alu3_pipeline

puts ""
puts "=================================================================="
puts " 2. CONSTRAINTS  (100 MHz  ->  clock period = 10 ns)"
puts "=================================================================="
create_clock -name clk -period 10.0 [get_ports clk]

set_input_delay  -clock clk -max 1.0 [get_ports {x c0 c1 c2 valid_in}]
set_input_delay  -clock clk -min 0.2 [get_ports {x c0 c1 c2 valid_in}]
set_input_delay  -clock clk -max 0.5 [get_ports rst_n]
set_input_delay  -clock clk -min 0.5 [get_ports rst_n]
set_output_delay -clock clk -max 1.0 [get_ports {y valid_out}]
set_output_delay -clock clk -min 0.2 [get_ports {y valid_out}]

set_clock_uncertainty 0.1 [get_clocks clk]
set_clock_transition  0.1 [get_clocks clk]

puts "clock period        : [get_property [get_clocks clk] period] ns"
puts "setup uncertainty   : 0.1 ns"
puts "input/output delay  : 1.0 ns (max) / 0.2 ns (min)  -  rst_n: 0.5 ns"

puts ""
puts "=================================================================="
puts " 3. SETUP TIMING  (report_checks -path_delay max)"
puts "=================================================================="
report_checks -path_delay max -sort_by_slack -endpoint_path_count 5 -digits 3

puts ""
puts "=================================================================="
puts " 4. HOLD TIMING  (report_checks -path_delay min)"
puts "=================================================================="
report_checks -path_delay min -sort_by_slack -endpoint_path_count 5 -digits 3

puts ""
puts "=================================================================="
puts " 5. WNS / TNS SUMMARY"
puts "=================================================================="
puts "Setup:"
report_wns -max -digits 3
report_tns -max -digits 3
puts "Hold:"
report_wns -min -digits 3
report_tns -min -digits 3
puts ""
puts "WNS = Worst Negative Slack (0.000 => no path has negative slack)"
puts "TNS = Total Negative Slack  (0.000 => no timing violations)"

puts ""
puts "STA complete."