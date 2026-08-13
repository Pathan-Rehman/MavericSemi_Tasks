# =====================================================================
# PD STEP 5: POST-ROUTE STATIC TIMING ANALYSIS (STA) + POWER
# =====================================================================
source scripts/pd_common.tcl

puts ""
puts "=================================================================="
puts " 1. READ DESIGN (liberty + lef + routed def + sdc)"
puts "=================================================================="
read_liberty $liberty
read_lef $tech_lef
read_lef $cell_lef
read_def $pd_dir/alu3_pipeline_routed.def
setup_tracks
setup_rc
read_sdc $sdc

puts ""
puts "=================================================================="
puts " 2. PARASITIC ESTIMATION (placement-based; RCX model unavailable in this PDK)"
puts "=================================================================="
estimate_parasitics -placement

puts ""
puts "=================================================================="
puts " 3. SETUP TIMING (report_checks -path_delay max)"
puts "=================================================================="
report_checks -path_delay max -sort_by_slack -endpoint_path_count 10 -digits 3

puts ""
puts "=================================================================="
puts " 4. HOLD TIMING (report_checks -path_delay min)"
puts "=================================================================="
report_checks -path_delay min -sort_by_slack -endpoint_path_count 10 -digits 3

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
puts "=================================================================="
puts " 6. POWER REPORT"
puts "=================================================================="
report_power

puts ""
puts "Post-route STA complete."