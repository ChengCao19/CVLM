import os

DEFAULT_TVD_MODEL_DIR = "TVDs_model"
DEFAULT_SVD_MODEL_DIR = "SVDs_model"

DEFAULT_MODELS = {
    "TVDs": {
        "segmentation": "Deeplabv3+",
        "detection": "YOLOv8-T"
    },
    "SVDs": {
        "segmentation": "UNet",
        "detection": "YOLOv8-S"
    }
}

IMAGE_EXTS = ('.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff')
OUTPUT_DIR = "CVLM_Results"
NUM_CLASSES = 2
INPUT_SIZE = (512, 512)
NORMALIZE_MEAN = [0.485, 0.456, 0.406]
NORMALIZE_STD = [0.229, 0.224, 0.225]
