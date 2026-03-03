# Run with:
#   klayout -b -r split_ws1_oasis.py \
#     -rd infile=/path/to/chip.oas \
#     -rd top=TOPCELL \
#     -rd outdir=out_gds
#
# Optional:
# TODO: document base, pattern
#   -rd base=XXXX  # select cells that have have 4 bytes followed by _.*
#   -rd pattern='^[A-Za-z0-9]{4}_.+$'   (default below)

import os, re, sys, gc
import pya
import builtins

def rd(name, default=None):
    # -rd variables are injected into the script interpreter namespace
    return getattr(builtins, name, globals().get(name, default))

def die(msg, code=1):
    print(f"ERROR: {msg}", file=sys.stderr, flush=True)
    sys.exit(code)

def main():
    infile  = rd("infile")
    base    = rd("base")
    topname = rd("top")
    outdir  = rd("outdir", ".")
    pattern = rd("pattern")

    if not infile:
        die("Missing -rd infile=/path/to/input.oas")
    if not os.path.isfile(infile):
        die(f"Input file not found: {infile}")
    if not topname:
        die("Missing -rd top=<top_cell_name>")

    os.makedirs(outdir, exist_ok=True)

    if pattern:
        # minimal glob (* only) -> regex
        # escape everything then replace \* with .*
        rx = "^" + re.escape(pattern).replace(r"\*", ".*") + "$"
        rx = rx.replace("X", r"[A-Za-z0-9]") 
    else:
        rx = "^" + re.escape(base) + "_.+$"
        rx = rx.replace("X", r"[A-Za-z0-9]") 

    print(f"rx={rx}")
    name_re = re.compile(rx)

    ly = pya.Layout()
    print(f"Reading {infile}")
    ly.read(infile)

    top = ly.cell(topname)
    if top is None:
        die(f'Top cell "{topname}" not found in layout.')

    # Collect unique direct-child cell names under top
    matches = set()
    for inst in top.each_inst():
        c = inst.cell
        if c is None:
            continue
        cname = c.name
        print(f"Found {cname}")
        if name_re.match(cname):
            matches.add(cname)

    prune_cells = ly.cells("{COMP,POLY2,METAL*}_FILL*")

    matches = sorted(matches)

    print(f"Input : {os.path.abspath(infile)}")
    print(f"Top   : {topname}")
    print(f"Outdir: {os.path.abspath(outdir)}")
    print(f"Regex : {pattern}")
    print(f"Matched top-level cells: {len(matches)}")
    print(f"Matched prune cells: {len(prune_cells)}")

    if not matches:
        print("Done (no matches).")
        return

    for prune_cell in prune_cells:
        print(f"Pruning {prune_cell.name}")
        ly.prune_cell(prune_cell.cell_index(), -1) # prune cell and children

    for cname in matches:
        out_path = os.path.join(outdir, f"{cname}.gds")
        slo = pya.SaveLayoutOptions()
        slo.write_context_info = True
        slo.add_cell(ly.cell(cname).cell_index())     # writes cname as top + its hierarchy
        ly.write(out_path, slo)
        print(f"Wrote: {out_path}")

    # Clean teardown (helps batch stability in some builds)
    del ly, top
    gc.collect()

if __name__ == "__main__":
    main()

