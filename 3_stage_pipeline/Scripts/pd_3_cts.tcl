# =====================================================================
# PD STEP 3: CLOCK TREE SYNTHESIS (CTS)
# =====================================================================
source scripts/pd_common.tcl

puts ""
puts "=================================================================="
puts " 1. READ DESIGN (liberty + lef + placed def + sdc)"
puts "=================================================================="
read_liberty $liberty
read_lef $tech_lef
read_lef $cell_lef
read_def $pd_dir/alu3_pipeline_placed.def
setup_tracks
setup_rc
read_sdc $sdc

set_routing_layers -signal met1-met5 -clock met4-met5

puts ""
puts "=================================================================="
puts " 2. CLOCK TREE SYNTHESIS"
puts "=================================================================="
clock_tree_synthesis \
    -root_buf sky130_fd_sc_hd__clkbuf_2 \
    -buf_list {sky130_fd_sc_hd__clkbuf_1 sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4} \
    -sink_clustering_enable \
    -sink_clustering_size 20 \
    -sink_clustering_max_diameter 60 \
    -distance_between_buffers 60 \
    -repair_clock_nets

puts ""
puts "=================================================================="
puts " 3. RE-DETAILED PLACEMENT (place clock buffers)"
puts "=================================================================="
detailed_placement

puts ""
puts "=================================================================="
puts " 4. WRITE CTS DEF"
puts "=================================================================="
write_def $pd_dir/alu3_pipeline_cts.def
puts "CTS DEF written to $pd_dir/alu3_pipeline_cts.def"