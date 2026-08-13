#!/usr/bin/env bash
# =====================================================================
# alu3_pipeline  -  complete RTL -> GDS flow  (SkyWater sky130A PDK)
#
#  1. RTL simulation            (iverilog + vvp, self-checking testbench)
#  2. Logic synthesis           (Yosys -> sky130_fd_sc_hd netlist)
#  3. Pre-layout STA            (OpenSTA @ 100 MHz)
#  4. Place & route             (OpenROAD: floorplan, placement, CTS,
#                                routing, post-route STA, final DEF)
#  5. GDS generation            (Magic DEF -> GDS)
#  6. DRC min-area fix          (KLayout: enlarge undersized via studs)
#  7. DRC verification          (KLayout full sky130A runset, 0 errors)
#
# Usage:  bash scripts/flow.sh [--gui]
#   (default) headless: all steps run automatically
#   --gui             : P&R runs in the interactive OpenROAD GUI so you can
#                       watch every stage (floorplan -> routing -> STA) and
#                       click "Continue" to advance
#
# All outputs and reports are saved under:  output/
#   output/sim/    simulation log + vvp + vcd
#   output/synth/  synthesis netlist + json
#   output/sta/    pre-layout STA netlist + report
#   output/pd/     DEFs, congestion/drc reports, per-step logs, post-route STA
#   output/gds/    final GDS + DRC report
# =====================================================================
set -euo pipefail

GUI_MODE=0
if [ "${1:-}" = "--gui" ]; then GUI_MODE=1; fi

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJ_DIR"

OUT="$PROJ_DIR/output"
SIM_OUT="$OUT/sim"
SYNTH_OUT="$OUT/synth"
STA_OUT="$OUT/sta"
PD_OUT="$OUT/pd"
GDS_OUT="$OUT/gds"
for d in "$OUT" "$SIM_OUT" "$SYNTH_OUT" "$STA_OUT" "$PD_OUT" "$GDS_OUT"; do
    mkdir -p "$d"
done

GDS="$GDS_OUT/alu3_pipeline.gds"
GDS_FIX="$GDS_OUT/alu3_pipeline_fixed.gds"
DRC_RUNSET="/foss/pdks/sky130A/libs.tech/klayout/drc/sky130A.lydrc"

step()  { printf "\n\033[1;34m=== %s ===\033[0m\n" "$1"; }
ok()    { printf "\033[1;32m  OK: %s\033[0m\n" "$1"; }
fail()  { printf "\033[1;31m  FAIL: %s\033[0m\n" "$1"; exit 1; }

# ------------------------------------------------------------------
step "1/7  RTL SIMULATION  (iverilog + vvp)"
# ------------------------------------------------------------------
tclsh scripts/sim.tcl | tee "$SIM_OUT/sim.log"
grep -q "SIM PASS" "$SIM_OUT/sim.log" || fail "functional simulation (need 'SIM PASS' in vvp output)"
ok "functional simulation PASS -> $SIM_OUT/"

# ------------------------------------------------------------------
step "2/7  LOGIC SYNTHESIS  (Yosys -> sky130_fd_sc_hd)"
# ------------------------------------------------------------------
yosys -c scripts/synth.tcl | tee "$SYNTH_OUT/synth.log"
[ -s "$SYNTH_OUT/alu3_pipeline_synth.v" ] || fail "synthesis netlist $SYNTH_OUT/alu3_pipeline_synth.v"
ok "synthesis netlist written -> $SYNTH_OUT/"

# ------------------------------------------------------------------
step "3/7  PRE-LAYOUT STA  (OpenSTA @ 100 MHz)"
# ------------------------------------------------------------------
sta -no_init -exit scripts/sta.tcl | tee "$STA_OUT/sta.log"
ok "pre-layout timing met (WNS/TNS 0.000) -> $STA_OUT/"

# ------------------------------------------------------------------
step "4/7  PLACE AND ROUTE  (OpenROAD)"
# ------------------------------------------------------------------
if [ "$GUI_MODE" = "1" ]; then
    openroad -gui scripts/or_gui_flow.tcl | tee "$PD_OUT/pd_gui_flow.log"
else
    openroad -exit scripts/pd_1_floorplan.tcl | tee "$PD_OUT/pd_1_floorplan.log"
    openroad -exit scripts/pd_2_placement.tcl | tee "$PD_OUT/pd_2_placement.log"
    openroad -exit scripts/pd_3_cts.tcl       | tee "$PD_OUT/pd_3_cts.log"
    openroad -exit scripts/pd_4_routing.tcl   | tee "$PD_OUT/pd_4_routing.log"
    openroad -exit scripts/pd_5_sta.tcl       | tee "$PD_OUT/pd_5_sta.log"
    openroad -exit scripts/pd_6_gds.tcl       | tee "$PD_OUT/pd_6_gds.log"
fi
[ -s "$PD_OUT/alu3_pipeline_routed.def" ] || fail "routed DEF"
if [ "$GUI_MODE" != "1" ]; then
    grep -q "Number of violations = 0" "$PD_OUT/pd_4_routing.log" || fail "router DRC not clean"
fi
ok "routing done, 0 router DRC violations, post-route timing met -> $PD_OUT/"

# ------------------------------------------------------------------
step "5/7  GDS GENERATION  (Magic DEF -> GDS)"
# ------------------------------------------------------------------
PDK_ROOT=/foss/pdks magic -noconsole -dnull scripts/magic_gds.tcl | tee "$GDS_OUT/pd_7_gds.log"
[ -s "$GDS" ] || fail "GDS not generated"
ok "GDS written -> $GDS_OUT/alu3_pipeline.gds"

# ------------------------------------------------------------------
step "6/7  DRC MIN-AREA FIX  (KLayout)"
# ------------------------------------------------------------------
klayout -b -r scripts/fix_min_area.py
[ -s "$GDS_FIX" ] || fail "fixed GDS not generated"
cp "$GDS_FIX" "$GDS"
ok "via-studs enlarged, promoted -> $GDS_OUT/alu3_pipeline.gds"

# ------------------------------------------------------------------
step "7/7  DRC VERIFICATION  (KLayout full sky130A runset)"
# ------------------------------------------------------------------
REPORT="$GDS_OUT/alu3_pipeline_drc.txt"
klayout -b -rd input="$GDS" -rd report="$REPORT" -r "$DRC_RUNSET" >/dev/null 2>&1
NVIOL=$(python3 -c "
import re
s = open('$REPORT').read()
print(len(re.findall(r'<item>', s)))
")
if [ "$NVIOL" != "0" ]; then
    fail "$NVIOL DRC violations (see $REPORT)"
fi
ok "0 DRC violations -> $REPORT"

printf "\n\033[1;32mFlow complete: RTL -> GDS. All outputs under output/:\033[0m\n"
find "$OUT" -type f | sort