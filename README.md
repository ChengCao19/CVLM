# CVLM

This repository contains the supporting code and data for the paper:

**Automated characterization of cotton leaf diurnal movement dynamics under field conditions using computer vision**

---

## Repository Structure

The project is organized into three main directories:

### A01_Figure
This folder contains all figures presented in the main manuscript and supplementary materials, organized sequentially:

- `Figure_1` to `Figure_10` — Main text figures
- `Supplementary Figure 1` — Supplementary material

Each subfolder holds the high-resolution source files and output plots for the corresponding figure.

### A02_Data_analysis
This folder houses the scripts used for model training, statistical data analysis, and figure generation. It includes:

- Model training pipelines
- Data processing and analysis workflows
- Plotting scripts for publication-ready figures

Corresponding outputs are organized under subfolders matching the figure names (e.g., `Figure_4`, `Figure_6`, `Figure_8`, `Figure_9`, `Figure_10`, `Supplementary Figure 1`).

### A03_CVLM_framework
This folder contains the core implementation of the **CVLM (Computer Vision Leaf Movement)** framework and the associated trained model weights:

- `SVDs_model` — Trained model weights for the SVDs
- `TVDs_model` — Trained model weights for the TVDs
- `CVLM` — The main CVLM source code

---

## Citation

If you use this code or data in your research, please cite the corresponding paper.

---

## Contact

For questions or issues regarding the code, please open an issue in this repository or contact the authors.
