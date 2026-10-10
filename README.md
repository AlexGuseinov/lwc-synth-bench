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
| Dipper-64/96 | 64 | 96 | SPN-ARX |
| Dipper-64/128 | 64 | 128 | SPN-ARX |

The Dipper cores (`dipper_rtl/`) are the round-based RTL of
[Dipper-lightweight-cipher](https://github.com/AlexGuseinov/Dipper-lightweight-cipher)
@ `26d0f05` (Huseynli, Imamverdiyev, Alizadeh, *Cryptography* 10(4), 52, 2026).
They go through the same flow as the other ciphers but are left out of the
inter-library calibration, so `calibration_results.csv` covers the six ciphers above them.

---

## Cell Libraries

- **Nangate45** — 45 nm open-source standard cell library
- **sky130** — SkyWater 130 nm PDK
- **ASAP7** — 7 nm predictive standard cell library

---

## Tools

- [Yosys](https://github.com/YosysHQ/yosys) — Open-source synthesis
- [ABC](https://github.com/berkeley-abc/abc) — Logic optimization and technology mapping

---

## Repository Structure

```
lwc-synth-bench/
├── rtl/                   # Verilog RTL sources
│   ├── gift/
│   ├── present/
│   ├── simon/
│   └── speck/
├── dipper_rtl/            # Dipper-64/96 and Dipper-64/128 RTL
├── libs/                  # Standard cell libraries
├── scripts/               # Synthesis automation scripts
│   ├── run_synth.py
│   └── speck_simon_ref.py
├── results/               # All synthesis outputs
│   ├── logs/              # Yosys synthesis logs per cipher/component
│   └── csv/               # GE results and calibration data
└── README.md
```

---

## Reproducing Results

**1. Install dependencies**
```bash
sudo apt install yosys
pip install pandas
```

**2. Run synthesis**
```bash
python scripts/run_synth.py
```

**3. Results** will be written to `results/csv/ge_results.csv` and `results/csv/synth_results.csv`.

---

## Results Summary

Gate equivalent (GE) results across libraries (full tables in `results/csv/`):

| Cipher | Component | Nangate45 (GE) | sky130 (GE) | ASAP7 (GE) |
|--------|-----------|----------------|-------------|------------|
| GIFT-64 | Full core | — | — | — |
| GIFT-128 | Full core | — | — | — |
| PRESENT-80 | Full core | — | — | — |
| PRESENT-128 | Full core | — | — | — |
| SIMON | Full core | — | — | — |
| SPECK | Full core | — | — | — |

> Fill in actual values from `results/csv/ge_results.csv` before publishing.

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
