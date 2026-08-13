# alu3_pipeline — RTL to GDS Full-Flow Report


<img width="1063" height="593" alt="image" src="https://github.com/user-attachments/assets/7f2ec89f-cb6e-4ff4-b89d-0f166a2feeed" />


A 3-stage synchronous pipelined **ALU** designed, verified, synthesized, placed-and-routed, and taken to GDSII using the open-source SkyWater **sky130A** PDK. The full flow — RTL simulation → logic synthesis → static timing analysis → place & route → GDS → DRC — is scripted and runs end-to-end with **zero timing violations and zero DRC violations**.

---

## 1. Design Overview

| Item | Value |
|---|---|
| Design name | `alu3_pipeline` |
| Description | 3-stage synchronous pipelined ALU |
| Data width | 32-bit operands (`a`, `b`), 32-bit result |
| Pipeline stages | 3 register stages: **REG → EX → WB** |
| Latency | `valid_out` asserts exactly 3 clocks after `valid_in` |
| Synchronization | Async active-low reset (`rst_n`), valid handshake (`valid_in`/`valid_out`) |
| Cell count | **1078 standard cells** (134 flip-flops) |
| Target clock | **100 MHz** (10 ns period) |
| Technology | SkyWater `sky130_fd_sc_hd` (typical: `tt_025C_1v80`) |
| Die size | **160 µm × 100 µm** |

### Architecture

```
                    +---------------------+      +---------------------+      +---------------------+
 clk ─────────────►  |   STAGE 1 (REG)      |      |   STAGE 2 (EX)       |      |   STAGE 3 (WB)      |
                    |  register operands   |      |  combinational ALU   |      |  writeback register |
 a,b,op,valid_in ──► |  a1,b1,op1,v1       |─────►|  alu_out = f(a1,b1)  |─────►|  result, valid_out  │──► outputs
                    +---------------------+      +---------------------+      +---------------------+
```

<img width="1918" height="1078" alt="image" src="https://github.com/user-attachments/assets/2ad4d188-aba5-4c5d-b2cf-64a868192363" />

The pipeline is deliberately kept simple to demonstrate the concept:

1. **Stage 1 – REG**: operands `a`, `b`, opcode `op` and the valid bit are captured in a register.
2. **Stage 2 – EX**: a combinational ALU computes the result from the *registered* operands.
3. **Stage 3 – WB**: the result and valid flag are re-registered to drive the outputs.

### ALU Operations (`op[2:0]`)

| op | Mnemonic | Operation |
|---|---|---|
| 000 | ADD | `result = a + b` |
| 001 | SUB | `result = a - b` |
| 010 | AND | `result = a & b` |
| 011 | OR  | `result = a \| b` |
| 100 | XOR | `result = a ^ b` |
| 101 | SLT | `result = (a < b) ? 1 : 0` (signed compare) |
| 110 | SLL | `result = a << b[4:0]` |
| 111 | SRL | `result = a >> b[4:0]` (logical) |

### I/O

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | input | 1 | Clock |
| `rst_n` | input | 1 | Asynchronous active-low reset |
| `valid_in` | input | 1 | Input valid strobe |
| `a` | input | 32 | Operand A |
| `b` | input | 32 | Operand B |
| `op` | input | 3 | ALU operation select |
| `valid_out` | output | 1 | Output valid strobe |
| `result` | output | 32 | ALU result |

---

## 2. Toolchain

| Tool | Version | Stage |
|---|---|---|
| iverilog / vvp | – | RTL simulation |
| Yosys | – | Logic synthesis |
| OpenSTA | – | Static timing analysis |
| OpenROAD | 26Q3-850 | Floorplan / placement / CTS / routing / STA |
| Magic | – | DEF → GDSII |
| KLayout | – | DRC + min-area fix |

PDK: `/foss/pdks/sky130A` (standard cell library `sky130_fd_sc_hd`).

---

## 3. Project Layout

```
pipeline_design/
├── rtl/        alu3_pipeline.sv          (RTL source)
├── sim/        tb_alu3_pipeline.sv       (self-checking testbench)
├── scripts/    flow.sh, run_pd.sh, synth/sta/sim.tcl,
│               pd_1..pd_6.tcl, magic_gds.tcl, fix_min_area.py, ...
└── output/     all results & reports
    ├── sim/    simulation log, vvp, vcd
    ├── synth/  synthesized netlist, json, synth log
    ├── sta/    pre-layout STA netlist + report
    ├── pd/     DEFs (floorplan/placed/cts/routed/final), per-step logs, reports
    └── gds/    GDSII + DRC report
```

---

## 4. RTL Verification

Self-checking testbench `sim/tb_alu3_pipeline.sv` with a reference model that mirrors the RTL register-for-register (REG → EX → WB), driven with random operands and opcodes.

**Command:** `tclsh scripts/sim.tcl`

```
SIM PASS: 200 outputs checked
```

Waveforms are dumped to `output/sim/tb_alu3_pipeline.vcd` (gtkwave).

---

## 5. Logic Synthesis (Yosys)

<img width="1918" height="1078" alt="image" src="https://github.com/user-attachments/assets/813b03e8-acc2-4bee-89d1-ed776e48528d" />

Reads `rtl/alu3_pipeline.sv`, maps to `sky130_fd_sc_hd` (`tt_025C_1v80` liberty).

**Command:** `yosys -c scripts/synth.tcl`

| Metric | Value |
|---|---|
| Total cells | **1078** |
| Unique cell types | 51 |
| Flip-flops | 134 (`dfrtp_1`) |
| Combinational area | 8612 µm² |

Most-used cells (top 10 of 51 types):

| Cell | Count |
|---|---|
| `a21oi_1` | 166 |
| `o21ai_0` | 137 |
| `nand2_1` | 135 |
| `dfrtp_1` | 134 |
| `nor2_1` | 118 |
| `mux2i_1` | 31 |
| `nor3_1` | 30 |
| `clkinv_1` | 29 |
| `nand2b_1` | 24 |
| `xnor2_1` | 23 |

Netlist: `output/synth/alu3_pipeline_synth.v`

---

## 6. Pre-Layout STA (OpenSTA)

Timing constraints (`scripts/alu3_pipeline.sdc`): 10 ns clock, 0.1 ns uncertainty, 1.0 ns input delay, 1.0 ns output delay.

**Command:** `sta -no_init -exit scripts/sta.tcl`

```
wns max 0.000     tns max 0.000
wns min 0.000     tns min 0.000
```

**No setup or hold violations at 100 MHz** before layout.

---

## 7. Place & Route (OpenROAD)

<img width="1918" height="1078" alt="image" src="https://github.com/user-attachments/assets/68a7752e-4771-4fee-ad23-08c94bbcced5" />

Runs as six steps (`pd_1_floorplan` → `pd_6_gds`), all orchestrated by `scripts/flow.sh`.

### 7.1 Floorplan
- Die: **160 µm × 100 µm**, core rows of `unithd` site
- Power grid: met1 rails + met4/met5 straps, tap cells + decaps added
- Effective utilization: **58.2%**

### 7.2 Placement
| Metric | Value |
|---|---|
| Total instances | 1259 (1078 movable + 181 fixed taps/decaps) |
| Movable area | 8612 µm² |

Legalized, zero overlaps.

### 7.3 Clock Tree Synthesis (CTS)
| Metric | Value |
|---|---|
| Clock sinks | 134 |
| Clock buffers inserted | 25 (`clkbuf_2`) |
| Buffer levels | 3 (H-tree) |
| Dummy loads inserted | 8 |

### 7.4 Routing (met1–met5)
| Metric | Value |
|---|---|
| Signals | 1173 nets |
| Router DRC | **0 violations** (final) |

### 7.5 Post-Route STA
Performed in a **fresh OpenROAD process** on the routed DEF with `estimate_parasitics -placement` (avoids the in-session parasitic corruption quirk of this OpenROAD build).

```
wns max 0.000     tns max 0.000      (setup, 100 MHz)
wns min 0.000     tns min 0.000      (hold)
```

**Power report (total 1.10 mW @ 100 MHz):**

| Group | Internal | Switching | Leakage | Total | Share |
|---|---|---|---|---|---|
| Sequential | 0.592 mW | 0.032 mW | 1.6 nW | 0.624 mW | 56.8% |
| Combinational | 0.099 mW | 0.099 mW | 1.9 nW | 0.197 mW | 18.0% |
| Clock | 0.164 mW | 0.112 mW | 0.4 nW | 0.276 mW | 25.2% |
| **Total** | **0.855 mW** | **0.243 mW** | **3.9 nW** | **1.10 mW** | 100% |

### 7.6 Final DEF
`output/pd/alu3_pipeline_final.def` — 1292 components, 1173 nets.

---

## 8. GDSII Generation (Magic)



OpenROAD's `write_gds` is unavailable in this build, so the final DEF is exported to GDSII via Magic.

**Command:** `PDK_ROOT=/foss/pdks magic -noconsole -dnull scripts/magic_gds.tcl`

| Item | Value |
|---|---|
| GDS file | `output/gds/alu3_pipeline.gds` (~493 KB) |
| Top cell | `alu3_pipeline` |
| Subcell instances | 1292 |
| Die | 160 µm × 100 µm |

---

## 9. Physical Verification (KLayout)

Full SkyWater `sky130A` DRC runset applied to the GDS.

**Initial result:** 1 violation — `m4.4` (met4 via stub below the 0.24 µm² minimum area).

**Fix:** `scripts/fix_min_area.py` enlarges undersized metal studs to the required area while respecting the minimum metal spacing (rules for met1–met4). The met4 stub was grown from 0.186 µm² → 0.245 µm².

**Final result: 0 DRC violations.**

```
OK: 0 DRC violations -> output/gds/alu3_pipeline_drc.txt
```

---

## 10. Results Summary

| Metric | Value |
|---|---|
| Functionality | SIM PASS (200 checks) |
| Standard cells | 1078 |
| Flip-flops | 134 |
| Frequency | 100 MHz |
| Pre-layout WNS/TNS | 0.000 / 0.000 |
| Post-route WNS/TNS (setup) | 0.000 / 0.000 |
| Post-route worst setup slack | +0.077 ns |
| Post-route WNS/TNS (hold) | 0.000 / 0.000 |
| Post-route worst hold slack | +0.085 ns |
| Total power | 1.10 mW |
| Die area | 160 µm × 100 µm (16,000 µm²) |
| Utilization | 58.2% |
| Router DRC | 0 violations |
| Physical DRC | 0 violations |
| Outputs | GDSII + final DEF + all reports in `output/` |

---

## 11. How to Run

Full flow (sim → GDS → DRC):

```bash
bash scripts/flow.sh
```

Interactive GUI mode (watch floorplan → routing → STA in OpenROAD GUI, click *Continue* per stage):

```bash
bash scripts/flow.sh --gui
```

View the routed/final layout:

```bash
DEF=output/pd/alu3_pipeline_final.def openroad -gui scripts/open_def_gui.tcl
```

View the GDSII (KLayout):

```bash
klayout -r scripts/open_gds.py
```

---

## 12. Notes & Known Caveats

- The sky130A PDK used here ships no OpenRCX model, so post-route timing uses placement-based parasitics (`estimate_parasitics -placement`) instead of SPEF — a common approximation. The design still meets 100 MHz with positive slack (worst setup +0.077 ns, worst hold +0.085 ns).
- This OpenROAD build cannot write GDS directly; Magic is used for the DEF→GDS step and KLayout for signoff DRC.
- Reading the routed DEF in a **fresh** OpenROAD process is required for clean post-route timing: in-session STA after `global_route` is corrupted by stale parasitic data (a build quirk), which `flow.sh` handles automatically.
- `iverilog` emits benign "sorry:" notices for constant selects and `unique case`; these are simulation-only and do not affect synthesis.
