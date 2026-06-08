#!/usr/bin/env python3
"""
run_synth.py  --  Multi-library GE benchmarking + predictive calibration

Hər (cipher x library) eyni RTL-i Yosys+ABC ilə sintez edir, GE hesablayır,
sonra Nangate45-ə görə inter-library calibration-ı PREDICTIV yoxlayır
(leave-one-out + SPN-fit / non-SPN-predict cross-class).

Çıxış: synth_results.csv, calibration_results.csv

İşə salmaq (Paper 2/ qovluğunda, Yosys PATH-də): python run_synth.py
"""

import csv, os, re, subprocess, sys, tempfile

# ----------------------------------------------------------------------
# CONFIG -- top adları fayl adı ilə eyni fərziyyəsi (güvən 7/10).
# SPECK/SIMON core-ları test-vektorla təsdiqlənib (iverilog).
# ----------------------------------------------------------------------
CIPHERS = [
    {"name": "PRESENT-80",   "rtl_dir": "present_rtl", "top": "present_core_80",  "class": "SPN"},
    {"name": "PRESENT-128",  "rtl_dir": "present_rtl", "top": "present_core_128", "class": "SPN"},
    {"name": "GIFT-64-128",  "rtl_dir": "gift_rtl",    "top": "gift64_core",      "class": "SPN"},
    {"name": "GIFT-128-128", "rtl_dir": "gift_rtl",    "top": "gift128_core",     "class": "SPN"},
    {"name": "SPECK-64-128", "rtl_dir": "speck_rtl",   "top": "speck_core_128",   "class": "ARX"},
    {"name": "SIMON-64-128", "rtl_dir": "simon_rtl",   "top": "simon_core_128",   "class": "Feistel"},
]

LIBRARIES = [
    {"name": "Nangate45", "node": "45nm",
     "files": ["libs/NangateOpenCellLibrary_typical.lib"]},
    {"name": "sky130", "node": "130nm",
     "files": ["libs/sky130_fd_sc_hd__tt_025C_1v80.lib"]},
    {"name": "ASAP7", "node": "7nm",
     "files": [
         "libs/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib",
         "libs/asap7sc7p5t_AO_RVT_TT_nldm_211120.lib",
         "libs/asap7sc7p5t_OA_RVT_TT_nldm_211120.lib",
         "libs/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib",
         "libs/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib",
     ]},
]

# Yalnız təsdiqlənmiş nəşr olunmuş GE-lər. SPECK üçün etibarlı rəqəm yoxdur -> None.
PUBLISHED_GE = {
    "PRESENT-80":   None,
    "PRESENT-128":  1560.0,
    "GIFT-64-128":  1345.0,
    "GIFT-128-128": 1997.0,
    "SIMON-64-128": 1458.0,   # mənbəni təsdiqlə
    "SPECK-64-128": None,
}

YOSYS = os.environ.get("YOSYS", "yosys")
OUT_CSV = "synth_results.csv"
CAL_CSV = "calibration_results.csv"
REF_LIB = "Nangate45"


# ----------------------------------------------------------------------
# Liberty parsing
# ----------------------------------------------------------------------
def _cell_area(text, cell_name):
    pat = r'cell\s*\(\s*"?' + re.escape(cell_name) + r'"?\s*\)\s*\{'
    m = re.search(pat, text)
    if not m:
        return None
    b = text.find("{", m.start())
    depth, i = 0, b
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                break
        i += 1
    am = re.search(r"area\s*:\s*([0-9.]+)", text[b:i])
    return float(am.group(1)) if am else None


def _nand2_candidates(text):
    names = re.findall(
        r'cell\s*\(\s*"?([^")\s]*[Nn][Aa][Nn][Dd]2[^")\s]*)"?\s*\)', text)
    out = []
    for n in names:
        if re.search(r"nand2b", n.lower()):   # yalnız inverted-input variantı at
            continue
        out.append(n)
    return sorted(set(out))


def pick_nand2(lib_files):
    text = ""
    for f in lib_files:
        with open(f, "r", errors="ignore") as fh:
            text += fh.read() + "\n"
    cands = []
    for name in _nand2_candidates(text):
        a = _cell_area(text, name)
        if a is not None and a > 0:
            cands.append((name, a))
    if not cands:
        return None, None
    drive1 = []
    for name, area in cands:
        low = name.lower()
        if (re.search(r"nand2_x1$", low) or re.search(r"nand2_1$", low)
                or re.search(r"nand2x1(?:_|$)", low)):
            drive1.append((name, area))
    pool = drive1 if drive1 else cands
    return min(pool, key=lambda t: t[1])


def merge_liberty(lib_files):
    if len(lib_files) == 1:
        return lib_files[0], None
    texts = []
    for f in lib_files:
        with open(f, "r", errors="ignore") as fh:
            texts.append(fh.read())
    head = texts[0][: texts[0].find("cell (")]
    cells = []
    for t in texts:
        first = t.find("cell (")
        last = t.rfind("}")
        if first != -1 and last > first:
            cells.append(t[first:last])
    merged = head + "\n".join(cells) + "\n}\n"
    tmp = tempfile.NamedTemporaryFile("w", suffix=".lib", delete=False)
    tmp.write(merged)
    tmp.close()
    return tmp.name, tmp.name


# ----------------------------------------------------------------------
# Yosys flow
# ----------------------------------------------------------------------
def run_yosys(rtl_files, top, lib_path):
    rfiles = " ".join(rtl_files)
    script = f"""
read_verilog {rfiles}
synth -top {top} -flatten
dfflibmap -liberty {lib_path}
abc -liberty {lib_path}
setundef -zero
opt -purge
clean -purge
stat -liberty {lib_path}
"""
    with tempfile.NamedTemporaryFile("w", suffix=".ys", delete=False) as ys:
        ys.write(script)
        ys_path = ys.name
    try:
        r = subprocess.run([YOSYS, "-s", ys_path], capture_output=True, text=True)
    finally:
        os.unlink(ys_path)
    out = r.stdout + "\n" + r.stderr
    area = None
    for line in out.splitlines():
        if "Chip area" in line:
            nums = re.findall(r"[0-9]+(?:\.[0-9]+)?", line)
            if nums:
                area = float(nums[-1])
                break
    return area, out, r.returncode


# ----------------------------------------------------------------------
# Predictive calibration (NEW)
# ----------------------------------------------------------------------
def calibrate(rows, ref=REF_LIB):
    libs = {}
    for r in rows:
        libs.setdefault(r["library"], {})[r["cipher"]] = (r["GE"], r["class"])
    if ref not in libs:
        return []
    out = []
    for lib, data in libs.items():
        if lib == ref:
            continue
        ciphers = [c for c in data if c in libs[ref]]
        if len(ciphers) < 2:
            continue
        ratios = {c: data[c][0] / libs[ref][c][0] for c in ciphers}
        a_glob = sum(ratios.values()) / len(ratios)
        loo_max = 0.0
        for j in ciphers:
            others = [ratios[c] for c in ciphers if c != j]
            aj = sum(others) / len(others)
            err = abs(aj * libs[ref][j][0] - data[j][0]) / data[j][0] * 100
            loo_max = max(loo_max, err)
        spn = [c for c in ciphers if data[c][1] == "SPN"]
        non = [c for c in ciphers if data[c][1] != "SPN"]
        a_spn = ""
        cross = ""
        if spn and non:
            a_spn = sum(ratios[c] for c in spn) / len(spn)
            cross = round(max(abs(a_spn * libs[ref][c][0] - data[c][0])
                              / data[c][0] * 100 for c in non), 1)
            a_spn = round(a_spn, 3)
        out.append({
            "target_library": lib, "n_ciphers": len(ciphers),
            f"alpha_vs_{ref}": round(a_glob, 3),
            "loo_max_resid_%": round(loo_max, 1),
            "alpha_SPN_only": a_spn, "crossclass_max_resid_%": cross,
        })
    return out


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
def main():
    rows = []
    for lib in LIBRARIES:
        n_name, n_area = pick_nand2(lib["files"])
        lib["nand2_cell"], lib["nand2_area"] = n_name, n_area
        if n_name is None:
            print(f"[XƏBƏRDARLIQ] {lib['name']}: NAND2 tapılmadı!")
        else:
            print(f"[NAND2] {lib['name']:10s} -> {n_name}  ({n_area} um^2)")

    for lib in LIBRARIES:
        if lib["nand2_area"] is None:
            continue
        lib_path, tmp = merge_liberty(lib["files"])
        try:
            for cip in CIPHERS:
                if not os.path.isdir(cip["rtl_dir"]):
                    print(f"[ATLA] {cip['name']}: '{cip['rtl_dir']}' yoxdur")
                    continue
                rtl = sorted(os.path.join(cip["rtl_dir"], f)
                             for f in os.listdir(cip["rtl_dir"]) if f.endswith(".v"))
                area, log, rc = run_yosys(rtl, cip["top"], lib_path)
                if area is None:
                    print(f"[XƏTA] {cip['name']} x {lib['name']} (rc={rc}).\n{log[-600:]}")
                    continue
                ge = area / lib["nand2_area"]
                pub = PUBLISHED_GE.get(cip["name"])
                dev = (ge / pub - 1) * 100 if pub else None
                rows.append({
                    "cipher": cip["name"], "class": cip["class"],
                    "library": lib["name"], "node": lib["node"],
                    "nand2_cell": lib["nand2_cell"],
                    "nand2_area": round(lib["nand2_area"], 6),
                    "chip_area_um2": round(area, 3), "GE": round(ge, 1),
                    "published_GE": pub,
                    "dev_vs_published_%": round(dev, 1) if dev is not None else "",
                })
                print(f"  {cip['name']:13s} {lib['name']:9s} "
                      f"area={area:10.2f}  GE={ge:8.1f}"
                      + (f"  dev={dev:+.1f}%" if dev is not None else ""))
        finally:
            if tmp:
                os.unlink(tmp)

    if not rows:
        print("Heç bir nəticə alınmadı.")
        sys.exit(1)

    with open(OUT_CSV, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"\nYazıldı -> {OUT_CSV}  ({len(rows)} sətr)")

    cal = calibrate(rows)
    if cal:
        with open(CAL_CSV, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(cal[0].keys()))
            w.writeheader()
            w.writerows(cal)
        print(f"\n--- Calibration (reference = {REF_LIB}) ---")
        for c in cal:
            print(c)
        print(f"Yazıldı -> {CAL_CSV}")
        print("\nİzah: loo_max_resid kiçikdirsə (<~5%) -> tək skalar bütün şifrlərə "
              "ümumiləşir. crossclass_max_resid SPN-də fit edib ARX/Feistel-i "
              "proqnozlaşdırma xətasıdır -> kiçikdirsə calibration arxitektura "
              "sinifləri arası keçərlidir (güclü iddia); böyükdürsə sinif-asılıdır.")


if __name__ == "__main__":
    main()