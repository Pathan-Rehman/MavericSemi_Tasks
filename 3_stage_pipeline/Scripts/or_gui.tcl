# Open the routed design in the OpenROAD GUI.
# Usage: openroad -gui scripts/or_gui.tcl

read_liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_lef /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_def output/pd/alu3_pipeline_routed.def
read_sdc scripts/alu3_pipeline.sdc

gui::fit
puts "GUI opened with routed design (output/pd/alu3_pipeline_routed.def)"