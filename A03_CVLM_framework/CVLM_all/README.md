# CVLM User Guide

## 1. Installation

Requires Python >= 3.9. Install dependencies:

```bash
pip install -r requirements.txt
```

## 2. Prepare Model Weights

Extract the official model package to the same directory as the program. Ensure the following structure exists:

```
TVDs_model/
├── Deeplabv3+/
├── HRNet/
├── PSPNet/
├── UNet/
└── YOLOv8-T/

SVDs_model/
├── Deeplabv3+/
├── HRNet/
├── PSPNet/
├── UNet/
└── YOLOv8-S/
```

Each subfolder should contain exactly one `.pt` or `.pth` weight file.

## 3. Launch

```bash
python main.py
```

## 4. Processing Data

1. **Select View Type**: Click the `TVDs` or `SVDs` radio button.
2. **Add Folders**: Click `Add Folder` to select a folder containing time-series leaf images. Multiple folders can be added.
3. **Select Model Mode**:
   - **Default**: Automatically loads default models (TVDs: Deeplabv3+ + YOLOv8-T; SVDs: U-Net + YOLOv8-S).
   - **Custom**: Manually specify four model files.
4. Click `Start Processing` and observe the progress bars and log.
5. Click `Cancel` to abort at any time.

## 5. Output

Results are saved to `CVLM_Results/` in the program directory:

| Output | Path |
|:---|:---|
| Parameter table | `CVLM_Results/CVLM_Results.xlsx` (TVDs / SVDs as separate sheets) |
| Mask overlay | `CVLM_Results/{View}_{FolderName}/mask_overlay/` |
| Trajectory overlay | `CVLM_Results/{View}_{FolderName}/trajectory_overlay/trajectory_overlay.png` |
| Vector trajectory | `CVLM_Results/{View}_{FolderName}/trajectory_vector/trajectory.svg` |

## 6. Parameters

**TVDs**
- `2D-LA` / `2D-LAR`: Leaf pixel area and area ratio
- `2D-LAV` / `2D-LARV`: Temporal derivatives of area and area ratio
- `2D-LSR` / `2D-LSRV`: Bounding box aspect ratio and its temporal derivative
- `centroid_x` / `centroid_y`: Centroid coordinates
- `interpolated`: Interpolated frame flag

**SVDs**
- `2D-VA` / `2D-VAR` / `2D-VAV` / `2D-VARV`: Side-view area parameters
- `2D-VSR` / `2D-VSRV`: Bounding box height/width ratio (Height/Width) and its temporal derivative
- `centroid_x` / `centroid_y` / `interpolated`

Temporal derivatives are computed using the actual time interval between adjacent images. If detection fails, the centroid is carried forward from the previous frame and marked as interpolated.
