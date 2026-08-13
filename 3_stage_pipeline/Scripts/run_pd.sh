#!/usr/bin/env bash
# Run the complete OpenROAD place-and-route flow for alu3_pipeline (sky130A).
# Usage: bash scripts/run_pd.sh
set -e
cd "$(dirname "$0")/.."
mkdir -p output/{sim,synth,sta,pd,gds}

echo "=================== PD STEP 1/6: FLOORPLAN ====================="
openroad -exit scripts/pd_1_floorplan.tcl 2>&1 | tee output/pd/pd_1_floorplan.log

echo "=================== PD STEP 2/6: PLACEMENT ======================"
openroad -exit scripts/pd_2_placement.tcl 2>&1 | tee output/pd/pd_2_placement.log

echo "=================== PD STEP 3/6: CTS ============================"
openroad -exit scripts/pd_3_cts.tcl 2>&1 | tee output/pd/pd_3_cts.log

echo "=================== PD STEP 4/6: ROUTING ========================"
openroad -exit scripts/pd_4_routing.tcl 2>&1 | tee output/pd/pd_4_routing.log

echo "=================== PD STEP 5/6: POST-ROUTE STA ================="
openroad -exit scripts/pd_5_sta.tcl 2>&1 | tee output/pd/pd_5_sta.log

echo "=================== PD STEP 6/6: FINAL DEF ======================="
openroad -exit scripts/pd_6_gds.tcl 2>&1 | tee output/pd/pd_6_gds.log

echo "=================== PD STEP 7: GDS (MAGIC) ======================="
PDK_ROOT=/foss/pdks magic -noconsole -dnull scripts/magic_gds.tcl 2>&1 | tee output/gds/pd_7_gds.log

echo ""
echo "PD flow complete. Results in output/pd/ and output/gds/:"
ls -la output/pd/*.def output/gds/*.gds 2>/dev/null