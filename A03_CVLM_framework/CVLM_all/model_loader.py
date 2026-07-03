import os
import glob
import torch
from torchvision import models


def find_weight_file(folder):
    if not os.path.exists(folder):
        return None
    files = glob.glob(os.path.join(folder, "*.pt")) + glob.glob(os.path.join(folder, "*.pth"))
    if len(files) == 1:
        return files[0]
    return None


def load_segmentation_model(model_path, model_name, device):
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")

    if "deeplab" in model_name.lower():
        model = models.segmentation.deeplabv3_resnet50(num_classes=2, aux_loss=False)
        state_dict = torch.load(model_path, map_location=device)
        model.load_state_dict(state_dict)
    elif "unet" in model_name.lower():
        from unet_model import UNet
        model = UNet(n_classes=2)
        state_dict = torch.load(model_path, map_location=device)
        model.load_state_dict(state_dict)
    else:
        raise ValueError(f"Unsupported segmentation model: {model_name}")

    model.to(device)
    model.eval()
    return model


def load_detection_model(model_path, device):
    from ultralytics import YOLO
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")
    return YOLO(model_path)
