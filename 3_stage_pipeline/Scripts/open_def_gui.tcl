# Open any DEF in the OpenROAD GUI.
# Usage: DEF=<def_path> openroad -gui scripts/open_def_gui.tcl
# Example: DEF=output/pd/alu3_pipeline_final.def openroad -gui scripts/open_def_gui.tcl
# (Run from the project directory, or use an absolute DEF path.)

set script_dir [file dirname [file normalize [info script]]]
set proj_dir   [file normalize [file join $script_dir ..]]

cd $proj_dir

if {[info exists env(DEF)] && $env(DEF) ne ""} {
    set def_path $env(DEF)
} else {
    set def_path "output/pd/alu3_pipeline_routed.def"
}
if {[file pathtype $def_path] ne "absolute"} {
    set def_path [file join $proj_dir $def_path]
}

read_liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_lef /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_def $def_path

gui::fit
puts "Opened $def_path in the GUI"
