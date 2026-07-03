# scripts/dataset.py

import os
from PIL import Image
import torch
from torch.utils.data import Dataset
import numpy as np


class SegmentationDataset(Dataset):
    def __init__(self, image_dir, mask_dir, transform=None, target_transform=None):
        """
        Args:
            image_dir (str): Directory containing input images.
            mask_dir (str): Directory containing ground-truth masks.
            transform (callable, optional): Transform to apply to images.
            target_transform (callable, optional): Transform to apply to masks.
        """
        self.image_dir = image_dir
        self.mask_dir = mask_dir
        self.transform = transform
        self.target_transform = target_transform
        self.images = [f for f in os.listdir(image_dir) if f.endswith(('.jpg', '.jpeg', '.png'))]

    def __len__(self):
        return len(self.images)

    def __getitem__(self, idx):
        img_name = self.images[idx]
        img_path = os.path.join(self.image_dir, img_name)
        mask_name = os.path.splitext(img_name)[0] + '.png'  # Assume mask is in PNG format
        mask_path = os.path.join(self.mask_dir, mask_name)

        # Verify that the corresponding mask file exists.
        if not os.path.exists(mask_path):
            raise FileNotFoundError(f"Mask file not found: {mask_path}")

        image = Image.open(img_path).convert('RGB')
        mask = Image.open(mask_path)

        if self.transform:
            image = self.transform(image)
        if self.target_transform:
            mask = self.target_transform(mask)
            mask = torch.as_tensor(np.array(mask), dtype=torch.long)  # Convert PIL -> NumPy -> Tensor

        return image, mask
