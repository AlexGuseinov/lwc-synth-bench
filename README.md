# lwc-synth-bench

**Reproducible Open-Source Synthesis Benchmark of Lightweight Block Cipher Cores Across Standard Cell Libraries**

This repository provides a fully reproducible synthesis benchmarking framework for lightweight block ciphers using open-source EDA tools. All RTL designs, synthesis scripts, cell libraries, and results are publicly available to support transparent and comparable hardware evaluations.

---

## Ciphers

| Cipher | Block (bits) | Key (bits) | Structure |
|--------|-------------|------------|-----------|
| GIFT-64 | 64 | 128 | SPN |
| GIFT-128 | 128 | 128 | SPN |
| PRESENT-80 | 64 | 80 | SPN |
| PRESENT-128 | 64 | 128 | SPN |
| SIMON | 64 | 128 | Feistel |
| SPECK | 64 | 128 | ARX |
| Dipper-64/96 ¹ | 64 | 96 | SPN-ARX |
| Dipper-64/128 ¹ | 64 | 128 | SPN-ARX |

¹ **Added after the paper; not part of its results.** The Dipper cores
(`dipper_rtl/`) are the round-based RTL of
[Dipper-lightweight-cipher](https://github.com/AlexGuseinov/Dipper-lightweight-cipher)
@ `26d0f05` (Huseynli, Imamverdiyev, Alizadeh, *Cryptography* 10(4), 52, 2026).
They go through the same, unchanged flow as the other ciphers but are left out
of the inter-library calibration, so `calibration_results.csv` covers the six
original ciphers only.

---

## Cell Libraries

- **Nangate45** — 45 nm open-source standard cell library
- **sky130** — SkyWater 130 nm PDK
- **ASAP7** — 7 nm predictive standard cell library

---

## Tools

- [Yosys](https://github.com/YosysHQ/yosys) 0.33 — Open-source synthesis
  (the Ubuntu 24.04 package; `synth_results.csv` reproduces exactly with it)
- [ABC](https://github.com/berkeley-abc/abc) (built into Yosys) — Logic optimization and technology mapping
- Python 3 (standard library only)

---

## Repository Structure

```
lwc-synth-bench/
├── gift_rtl/              # GIFT-64-128 and GIFT-128-128 RTL
├── present_rtl/           # PRESENT-80 and PRESENT-128 RTL
├── simon_rtl/             # SIMON-64/128 RTL
├── speck_rtl/             # SPECK-64/128 RTL
├── dipper_rtl/            # Dipper-64/96 and Dipper-64/128 RTL (added after the paper)
├── libs/                  # Standard cell libraries (Liberty)
├── scripts/
│   ├── run_synth.py       # synthesis of all cores x libraries + calibration
│   └── speck_simon_ref.py # Python reference of SPECK/SIMON, checks the official vectors
├── results/
│   ├── logs/              # Yosys logs per core/component
│   └── csv/
│       ├── synth_results.csv      # GE per cipher and library (output of run_synth.py)
│       ├── calibration_results.csv# inter-library calibration (output of run_synth.py)
│       ├── ge_results.csv         # Nangate45 full-core results
│       └── ge_components.csv      # Nangate45 round / key-schedule components
└── README.md
```

---

## Reproducing Results

**1. Install Yosys** (0.33 for identical numbers)
```bash
sudo apt install yosys
```

**2. Run synthesis** from the repository root
```bash
python3 scripts/run_synth.py
```

**3. Results**: `synth_results.csv` and `calibration_results.csv` are written to
the current directory; the committed copies are in `results/csv/`.

**Optional — check the SPECK/SIMON references**
```bash
python3 scripts/speck_simon_ref.py
```

---

## Results Summary

Gate equivalents of the full cores (from `results/csv/synth_results.csv`):

| Cipher | Nangate45 (GE) | sky130 (GE) | ASAP7 (GE) |
|--------|----------------|-------------|------------|
| GIFT-64-128 | 2196.7 | 2303.0 | 1352.8 |
| GIFT-128-128 | 3399.0 | 3470.7 | 2161.0 |
| PRESENT-80 | 2386.0 | 2354.3 | 1436.3 |
| PRESENT-128 | 2963.0 | 2886.3 | 1749.7 |
| SIMON-64/128 | 2812.3 | 3098.0 | 1847.8 |
| SPECK-64/128 | 2943.0 | 3008.3 | 1875.2 |
| Dipper-64/96 ¹ | 2497.7 | 2504.0 | 1565.0 |
| Dipper-64/128 ¹ | 2824.0 | 2810.3 | 1739.3 |

¹ Added after the paper; not part of its results.

---

## Citation

If you use this benchmark in your research, please cite:

```bibtex
@inproceedings{huseynli2026lwcbench,
  title     = {Reproducible Open-Source Synthesis Benchmark of Lightweight Block Cipher Cores Across Standard Cell Libraries},
  author    = {Huseynli, Ali and Alizadeh, Jalal and Imamverdiyev, Yadigar and Soltanmuradov, Vafali},
  booktitle = {},
  year      = {2026}
}
```

---

## License

MIT License
