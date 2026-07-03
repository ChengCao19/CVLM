# scripts/model.py

import torch
from torchvision import models
import torch.nn as nn


def get_model(num_classes):
    """
    Get a DeepLabv3+ model with a custom classifier head.

    Args:
        num_classes (int): Number of classes, including background.

    Returns:
        model (torch.nn.Module): DeepLabv3+ model instance.
    """
    # Load pretrained DeepLabv3 with ResNet-101 backbone.
    # Use 'weights' instead of the deprecated 'pretrained' argument.
    model = models.segmentation.deeplabv3_resnet101(
        weights=models.segmentation.DeepLabV3_ResNet101_Weights.DEFAULT,
        progress=True
    )
    # Replace the classifier head to match the target number of classes.
    model.classifier = models.segmentation.deeplabv3.DeepLabHead(2048, num_classes)
    return model
