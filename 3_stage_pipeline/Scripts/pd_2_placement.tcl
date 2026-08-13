# =====================================================================
# PD STEP 2: GLOBAL + DETAILED PLACEMENT
# =====================================================================
source scripts/pd_common.tcl

puts ""
puts "=================================================================="
puts " 1. READ DESIGN (liberty + lef + floorplan def)"
puts "=================================================================="
read_liberty $liberty
read_lef $tech_lef
read_lef $cell_lef
read_def $pd_dir/alu3_pipeline_floorplan.def
setup_tracks

puts ""
puts "=================================================================="
puts " 2. GLOBAL PLACEMENT"
puts "=================================================================="
global_placement -density 0.6

puts ""
puts "=================================================================="
puts " 3. DETAILED PLACEMENT"
puts "=================================================================="
detailed_placement

puts ""
puts "=================================================================="
puts " 4. WRITE PLACED DEF"
puts "=================================================================="
write_def $pd_dir/alu3_pipeline_placed.def
puts "Placed DEF written to $pd_dir/alu3_pipeline_placed.def"