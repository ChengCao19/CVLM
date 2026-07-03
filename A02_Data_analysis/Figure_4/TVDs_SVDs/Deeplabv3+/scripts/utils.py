# scripts/utils.py

import os
import shutil
import random
from tqdm import tqdm


def split_dataset(image_dir, mask_dir, output_dir, train_ratio=0.7, val_ratio=0.15, test_ratio=0.15, seed=42):
    """
    Split the dataset into training, validation, and test sets,
    and copy the corresponding files into separate folders.

    Args:
        image_dir (str): Directory containing image files.
        mask_dir (str): Directory containing mask files.
        output_dir (str): Root directory for the split datasets.
        train_ratio (float): Proportion of the training set.
        val_ratio (float): Proportion of the validation set.
        test_ratio (float): Proportion of the test set.
        seed (int): Random seed for reproducibility.
    """
    # Use a tolerance-based check to avoid floating-point precision issues.
    assert abs(train_ratio + val_ratio + test_ratio - 1.0) < 1e-6, "Ratios must sum to 1."

    images = [f for f in os.listdir(image_dir) if f.endswith(('.jpg', '.jpeg', '.png'))]
    random.seed(seed)
    random.shuffle(images)

    total = len(images)
    train_end = int(total * train_ratio)
    val_end = train_end + int(total * val_ratio)

    splits = {
        'train': images[:train_end],
        'val': images[train_end:val_end],
        'test': images[val_end:]
    }

    for split, split_images in splits.items():
        split_image_dir = os.path.join(output_dir, split, 'image')
        split_mask_dir = os.path.join(output_dir, split, 'label')
        os.makedirs(split_image_dir, exist_ok=True)
        os.makedirs(split_mask_dir, exist_ok=True)

        for img_file in tqdm(split_images, desc=f'Copying {split} files'):
            img_src = os.path.join(image_dir, img_file)
            img_dst = os.path.join(split_image_dir, img_file)
            shutil.copyfile(img_src, img_dst)

            mask_file = os.path.splitext(img_file)[0] + '.png'  # Assume masks are in PNG format
            mask_src = os.path.join(mask_dir, mask_file)
            mask_dst = os.path.join(split_mask_dir, mask_file)
            if os.path.exists(mask_src):
                shutil.copyfile(mask_src, mask_dst)
            else:
                print(f"Warning: Mask file {mask_src} does not exist.")
