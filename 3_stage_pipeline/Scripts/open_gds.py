# Usage: klayout -r scripts/open_gds.py
import pya

gds = "/foss/designs/pipeline_design/output/gds/alu3_pipeline.gds"
lyp = "/foss/pdks/sky130A/libs.tech/klayout/tech/sky130A.lyp"

mw = pya.Application.instance().main_window()
lv = mw.create_layout(1)
lv.load_layout(gds)
lv.load_layer_props(lyp)
lv.set_config("grid-visible", "false")
cv = lv.active_cellview()
lv.zoom_fit()
print("Opened", gds, "with", lyp)
