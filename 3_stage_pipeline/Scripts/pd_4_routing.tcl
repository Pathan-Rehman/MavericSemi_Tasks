# =====================================================================
# PD STEP 4: GLOBAL + DETAILED ROUTING
# =====================================================================
source scripts/pd_common.tcl

puts ""
puts "=================================================================="
puts " 1. READ DESIGN (liberty + lef + cts def + sdc)"
puts "=================================================================="
read_liberty $liberty
read_lef $tech_lef
read_lef $cell_lef
read_def $pd_dir/alu3_pipeline_cts.def
setup_tracks
setup_rc
read_sdc $sdc

set_routing_layers -signal met1-met5 -clock met4-met5

puts ""
puts "=================================================================="
puts " 2. GLOBAL ROUTING"
puts "=================================================================="
global_route -congestion_report_file $pd_dir/alu3_pipeline_congestion.rpt

puts ""
puts "=================================================================="
puts " 3. DETAILED ROUTING"
puts "=================================================================="
detailed_route -output_drc $pd_dir/alu3_pipeline_droute.rpt

puts ""
puts "=================================================================="
puts " 4. WRITE ROUTED DEF"
puts "=================================================================="
write_def $pd_dir/alu3_pipeline_routed.def
puts "Routed DEF written to $pd_dir/alu3_pipeline_routed.def"