# Usage: PDK_ROOT=/foss/pdks magic -d X11 scripts/magic_open_gds.tcl
# NOTE: do NOT source sky130A.magicrc here - magic sources it automatically
# at startup. Double-sourcing causes "command already exists" errors.

gds read /foss/designs/pipeline_design/output/gds/alu3_pipeline.gds
flatten
bbox
