# =====================================================================
# INTERACTIVE GUI FLOW - run the whole P&R in one OpenROAD GUI session.
# The design is shown after every stage; click "Continue" in the GUI
# to advance to the next stage.
#
# Usage:  openroad -gui scripts/or_gui_flow.tcl
# =====================================================================
source scripts/pd_common.tcl

proc show_stage {name} {
    puts "=============================================================="
    puts " STAGE: $name"
    puts "   The design is shown in the GUI window."
    puts "   Inspect it, then click 'Continue' to proceed."
    puts "=============================================================="
    gui::fit
    gui::pause
}

puts ""
puts "=================================================================="
puts " 1. READ DESIGN (liberty + lef + netlist + sdc)"
puts "=================================================================="
read_liberty $liberty
read_lef $tech_lef
read_lef $cell_lef
read_verilog $netlist
link_design alu3_pipeline
read_sdc $sdc
setup_rc

add_global_connection -net VDD -pin_pattern VPWR -inst_pattern .* -power
add_global_connection -net VSS -pin_pattern VGND -inst_pattern .* -ground

puts ""
puts "=================================================================="
puts " 2. FLOORPLAN  (die 160x100 um)"
puts "=================================================================="
initialize_floorplan -die_area {0 0 160 100} -core_area {2 2 158 98} -site unithd
setup_tracks

tapcell -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 \
        -endcap_master sky130_fd_sc_hd__decap_3 \
        -distance 25

set_voltage_domain -name CORE -power VDD -ground VSS
define_pdn_grid -name stdcell_grid -starts_with POWER \
                -voltage_domains {CORE} -pins {met1}
add_pdn_stripe -grid stdcell_grid -layer met4 -width 1.6 -pitch 20 -offset 10 -spacing 1.6 -starts_with POWER
add_pdn_stripe -grid stdcell_grid -layer met5 -width 1.6 -pitch 20 -offset 10 -spacing 1.6 -starts_with POWER
add_pdn_connect -grid stdcell_grid -layers {met4 met5}
add_pdn_stripe -grid stdcell_grid -layer met1 -width 0.17 -followpins
add_pdn_connect -grid stdcell_grid -layers {met1 met4}
pdngen

place_pins -hor_layers met3 -ver_layers met2 -corner_avoidance 5 -min_distance 2
gui::show
show_stage "1. Floorplan + PDN grid (160x100 um die, taps, power straps)"

puts ""
puts "=================================================================="
puts " 3. PLACEMENT  (global + detailed)"
puts "=================================================================="
global_placement -density 0.6
detailed_placement
show_stage "2. Placement (cells legalized, ~70% utilization)"

puts ""
puts "=================================================================="
puts " 4. CLOCK TREE SYNTHESIS"
puts "=================================================================="
set_routing_layers -signal met1-met5 -clock met4-met5
clock_tree_synthesis \
    -root_buf sky130_fd_sc_hd__clkbuf_2 \
    -buf_list {sky130_fd_sc_hd__clkbuf_1 sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4} \
    -sink_clustering_enable \
    -sink_clustering_size 20 \
    -sink_clustering_max_diameter 60 \
    -distance_between_buffers 60 \
    -repair_clock_nets
detailed_placement
show_stage "3. CTS (clock tree buffers added)"

puts ""
puts "=================================================================="
puts " 5. ROUTING  (global + detailed)"
puts "=================================================================="
global_route -congestion_report_file $pd_dir/alu3_pipeline_congestion.rpt
detailed_route -output_drc $pd_dir/alu3_pipeline_droute.rpt
show_stage "4. Routing (met1-met5, all nets routed)"

puts ""
puts "=================================================================="
puts " 6. POST-ROUTE STA  (100 MHz)"
puts "=================================================================="
puts "Writing routed DEF, then running STA in a fresh process"
puts "(avoids the in-session global-routing parasitic corruption)."
write_def $pd_dir/alu3_pipeline_routed.def
exec openroad -exit scripts/pd_5_sta.tcl > $pd_dir/pd_5_sta.log 2>&1
puts "Setup:"
puts [exec grep -E "wns max|tns max" $pd_dir/pd_5_sta.log]
puts "Hold:"
puts [exec grep -E "wns min|tns min" $pd_dir/pd_5_sta.log]
show_stage "5. Post-route timing (setup WNS/TNS 0.000 => MET)"

puts ""
puts "=================================================================="
puts " 7. WRITE FINAL DEF"
puts "=================================================================="
write_def $pd_dir/alu3_pipeline_routed.def
write_def $pd_dir/alu3_pipeline_final.def
puts "Final DEF written to $pd_dir/alu3_pipeline_final.def"

puts ""
puts "Interactive GUI flow complete. Close the GUI window to exit."