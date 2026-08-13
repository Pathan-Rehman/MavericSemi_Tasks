# Shared paths/config for the OpenROAD place-and-route flow (sky130A).
# Sourced at the top of every pd_*.tcl step script.

set script_dir [file dirname [file normalize [info script]]]
set proj_dir   [file normalize [file join $script_dir ..]]
set out_root   [file join $proj_dir output]
set pd_dir     [file join $out_root pd]
set synth_dir  [file join $out_root synth]
set sta_dir    [file join $out_root sta]

set pdk_dir    /foss/pdks/sky130A
set lib_dir    [file join $pdk_dir libs.ref sky130_fd_sc_hd]

set liberty    [file join $lib_dir lib sky130_fd_sc_hd__tt_025C_1v80.lib]
set tech_lef   [file join $lib_dir techlef sky130_fd_sc_hd__nom.tlef]
set cell_lef   [file join $lib_dir lef sky130_fd_sc_hd.lef]
set cell_gds   [file join $lib_dir gds sky130_fd_sc_hd.gds]
set netlist_synth [file join $synth_dir alu3_pipeline_synth.v]
set netlist      [file join $synth_dir alu3_pipeline_pd.v]
set sdc          [file join $script_dir alu3_pipeline.sdc]

if {![file exists $netlist]} {
    exec sed -e {s/signed //g} $netlist_synth > $netlist
}

foreach dir [list $out_root $pd_dir $synth_dir $sta_dir] {
    file mkdir $dir
}

proc setup_tracks {} {
    make_tracks li1 -x_pitch 0.46 -x_offset 0.23
    make_tracks met1 -y_pitch 0.34 -y_offset 0.17
    make_tracks met2 -x_pitch 0.46 -x_offset 0.23
    make_tracks met3 -y_pitch 0.68 -y_offset 0.34
    make_tracks met4 -x_pitch 0.92 -x_offset 0.46
    make_tracks met5 -y_pitch 1.40 -y_offset 0.72
}

proc setup_rc {} {
    set_layer_rc -layer li1  -resistance 8.4   -capacitance 0.24
    set_layer_rc -layer met1 -resistance 0.133 -capacitance 0.17
    set_layer_rc -layer met2 -resistance 0.133 -capacitance 0.17
    set_layer_rc -layer met3 -resistance 0.082 -capacitance 0.17
    set_layer_rc -layer met4 -resistance 0.082 -capacitance 0.17
    set_layer_rc -layer met5 -resistance 0.009 -capacitance 0.17
}