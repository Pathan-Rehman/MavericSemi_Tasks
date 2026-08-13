# =====================================================================
# PD STEP 1: FLOORPLAN + TAP/ENDCAP + POWER DELIVERY NETWORK (PDN)
# =====================================================================
source scripts/pd_common.tcl

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

puts ""
puts "=================================================================="
puts " 2. GLOBAL POWER CONNECTIONS  (VDD->VPWR, VSS->VGND)"
puts "=================================================================="
add_global_connection -net VDD -pin_pattern VPWR -inst_pattern .* -power
add_global_connection -net VSS -pin_pattern VGND -inst_pattern .* -ground

puts ""
puts "=================================================================="
puts " 3. FLOORPLAN  (50% utilization, square core)"
puts "=================================================================="
initialize_floorplan -die_area {0 0 160 100} -core_area {2 2 158 98} -site unithd

puts ""
puts "=================================================================="
puts " 4. ROUTING TRACKS  (make_tracks)"
puts "=================================================================="
setup_tracks

puts ""
puts "=================================================================="
puts " 5. TAP CELLS + ENDCAPS"
puts "=================================================================="
tapcell -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 \
        -endcap_master sky130_fd_sc_hd__decap_3 \
        -distance 25

puts ""
puts "=================================================================="
puts " 6. POWER DELIVERY NETWORK  (met1 rails + met4/met5 straps + ring)"
puts "=================================================================="
set_voltage_domain -name CORE -power VDD -ground VSS

define_pdn_grid -name stdcell_grid -starts_with POWER \
                -voltage_domains {CORE} \
                -pins {met1}

add_pdn_stripe -grid stdcell_grid -layer met4 -width 1.6 -pitch 20 -offset 10 -spacing 1.6 -starts_with POWER
add_pdn_stripe -grid stdcell_grid -layer met5 -width 1.6 -pitch 20 -offset 10 -spacing 1.6 -starts_with POWER
add_pdn_connect -grid stdcell_grid -layers {met4 met5}

add_pdn_stripe -grid stdcell_grid -layer met1 -width 0.17 -followpins
add_pdn_connect -grid stdcell_grid -layers {met1 met4}

pdngen

puts ""
puts "=================================================================="
puts " 7. PLACE I/O PINS"
puts "=================================================================="
place_pins -hor_layers met3 -ver_layers met2 -corner_avoidance 5 -min_distance 2

puts ""
puts "=================================================================="
puts " 8. WRITE FLOORPLAN DEF"
puts "=================================================================="
write_def $pd_dir/alu3_pipeline_floorplan.def
puts "Floorplan DEF written to $pd_dir/alu3_pipeline_floorplan.def"