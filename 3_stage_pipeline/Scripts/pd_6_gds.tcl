# =====================================================================
# PD STEP 6: WRITE FINAL DEF + GDS (layout is merged via KLayout)
# =====================================================================
source scripts/pd_common.tcl

puts ""
puts "=================================================================="
puts " 1. READ DESIGN (liberty + lef + routed def)"
puts "=================================================================="
read_liberty $liberty
read_lef $tech_lef
read_lef $cell_lef
read_def $pd_dir/alu3_pipeline_routed.def
setup_tracks

puts ""
puts "=================================================================="
puts " 2. WRITE FINAL DEF"
puts "=================================================================="
write_def $pd_dir/alu3_pipeline_final.def

puts ""
puts "=================================================================="
puts " 3. GDS NOTE (OpenROAD has no GDS writer; GDS generated via Magic)"
puts "=================================================================="
puts "Run: PDK_ROOT=/foss/pdks magic -noconsole -dnull scripts/magic_gds.tcl"