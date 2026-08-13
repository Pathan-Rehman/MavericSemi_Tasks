# Enlarge via studs below sky130 min-area until they meet the rule,
# while keeping at least the metal min-spacing to all neighbours.
# Usage: klayout -b -r scripts/fix_min_area.py
import pya

GDS = "/foss/designs/pipeline_design/output/gds/alu3_pipeline.gds"
GDS_FIX = "/foss/designs/pipeline_design/output/gds/alu3_pipeline_fixed.gds"

# (layer, datatype) -> (min_area um2, min_spacing um)
RULES = {
    (68, 20): (0.083, 0.14),   # met1  m1.6 / m1.2
    (69, 20): (0.0676, 0.14),  # met2  m2.6 / m2.2
    (70, 20): (0.24, 0.30),    # met3  m3.6 / m3.2
    (71, 20): (0.24, 0.30),    # met4  m4.4 / m4.2
}

ly = pya.Layout()
ly.read(GDS)
top = ly.top_cell()
dbu = ly.dbu
dbu2 = dbu * dbu

total_fixed = 0
total_failed = 0
reports = []

for (layer, dt), (min_area, min_space) in RULES.items():
    li = ly.layer(layer, dt)
    shapes = top.shapes(li)
    allr = pya.Region()
    for s in shapes.each():
        if s.is_polygon():
            allr.insert(s.polygon)
        elif s.is_box():
            allr.insert(s.box)
    if allr.is_empty():
        continue

    target_area = min_area / dbu2
    guard_dist = round(min_space / dbu)
    grow_step = max(1, round(0.005 / dbu))

    fixed_here = 0
    failed_here = 0
    new_shapes = []

    for poly in allr.each():
        if poly.area() >= target_area:
            new_shapes.append(poly)
            continue
        others = allr - pya.Region(poly)
        guard = others.sized(guard_dist)
        best = None
        for d in range(grow_step, 200 + 1, grow_step):  # up to 0.2 um growth
            g = poly.sized(d)
            if not (pya.Region(g) & guard).is_empty():
                break  # would violate spacing -> stop growing
            if g.area() >= target_area:
                best = g
                break
        if best is not None:
            new_shapes.append(best)
            fixed_here += 1
            reports.append(f"  layer({layer},{dt}) area {poly.area()*dbu2:.4f} -> {best.area()*dbu2:.4f} um2")
        else:
            new_shapes.append(poly)
            failed_here += 1

    shapes.clear()
    for p in new_shapes:
        shapes.insert(p)
    total_fixed += fixed_here
    total_failed += failed_here
    print(f"layer ({layer},{dt}): fixed {fixed_here}, could not fix {failed_here}")

print(f"TOTAL fixed: {total_fixed}, failed: {total_failed}")
for r in reports:
    print(r)

ly.write(GDS_FIX)
print("wrote", GDS_FIX)
