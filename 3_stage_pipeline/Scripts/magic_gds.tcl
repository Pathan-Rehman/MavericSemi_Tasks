# =====================================================================
# GDS GENERATION VIA MAGIC (DEF -> GDS using sky130A tech)
#   magic -noconsole -dnull scripts/magic_gds.tcl
# =====================================================================
source /foss/pdks/sky130A/libs.tech/magic/sky130A.magicrc

set proj_dir /foss/designs/pipeline_design
set pd_dir $proj_dir/output/pd
set gds_dir $proj_dir/output/gds
file mkdir $gds_dir

puts "Reading DEF: $pd_dir/alu3_pipeline_final.def"
def read $pd_dir/alu3_pipeline_final.def

puts "Writing GDS: $gds_dir/alu3_pipeline.gds"
gds write $gds_dir/alu3_pipeline.gds

puts "=== magic DEF->GDS done ==="
quit -noprompt
