# scripts/test.py

import torch
import numpy as np
from tqdm import tqdm


def test_model(model, test_loader, device, num_classes):
    """
    Evaluate the model on the test set and compute the following metrics:
    1. Pixel Accuracy (PA)
    2. Mean Pixel Accuracy (mPA)
    3. Mean Intersection over Union (mIoU)
    4. Dice Coefficient (F1 Score), averaged across classes
    5. Frequency Weighted IoU (FWIoU)
    6. Precision and Recall, averaged across classes

    Args:
        model (torch.nn.Module): Trained model.
        test_loader (DataLoader): Test set DataLoader.
        device (torch.device): Computation device (CPU/GPU).
        num_classes (int): Number of classes, including background.
    """
    model.eval()
    model.to(device)

    # Accumulators for metric computation
    total_pixels = 0           # Total number of pixels
    correct_pixels = 0         # Correctly classified pixels
    intersection = np.zeros(num_classes)  # True Positives (TP)
    union = np.zeros(num_classes)         # TP + FP + FN
    pred_sum = np.zeros(num_classes)      # Predicted pixels per class (TP + FP)
    target_sum = np.zeros(num_classes)    # Ground-truth pixels per class (TP + FN)

    with torch.no_grad():
        for images, masks in tqdm(test_loader, desc='Testing'):
            images = images.to(device)
            masks = masks.to(device)

            # Forward pass
            outputs = model(images)['out']
            preds = torch.argmax(outputs, dim=1)

            # Global pixel counts
            total_pixels += masks.numel()
            correct_pixels += (preds == masks).sum().item()

            # Per-class statistics
            for cls in range(num_classes):
                pred_inds = (preds == cls)
                target_inds = (masks == cls)
                intersection[cls] += (pred_inds & target_inds).sum().item()
                union[cls] += (pred_inds | target_inds).sum().item()
                pred_sum[cls] += pred_inds.sum().item()
                target_sum[cls] += target_inds.sum().item()

    # 1. Pixel Accuracy (PA)
    pixel_accuracy = correct_pixels / total_pixels

    # 2. Mean Pixel Accuracy (mPA)
    with np.errstate(divide='ignore', invalid='ignore'):
        per_class_pa = intersection / target_sum
    mPA = np.nanmean(per_class_pa)

    # 3. Mean Intersection over Union (mIoU)
    with np.errstate(divide='ignore', invalid='ignore'):
        iou = intersection / union
    mean_iou = np.nanmean(iou)

    # 4. Dice Coefficient (F1 Score)
    with np.errstate(divide='ignore', invalid='ignore'):
        dice = 2 * intersection / (pred_sum + target_sum)
    mean_dice = np.nanmean(dice)

    # 5. Frequency Weighted IoU (FWIoU)
    freq = target_sum / total_pixels
    fwIoU = (freq[freq > 0] * iou[freq > 0]).sum()

    # 6. Precision and Recall
    with np.errstate(divide='ignore', invalid='ignore'):
        precision = intersection / pred_sum
        recall = intersection / target_sum
    mean_precision = np.nanmean(precision)
    mean_recall = np.nanmean(recall)

    # Compile results into a dictionary
    test_results = {
        "Test Pixel Accuracy (PA)": pixel_accuracy,
        "Test Mean Pixel Accuracy (mPA)": mPA,
        "Test Mean IoU (mIoU)": mean_iou,
        "Test Mean Dice Coefficient (F1)": mean_dice,
        "Test Frequency Weighted IoU (FWIoU)": fwIoU,
        "Test Mean Precision": mean_precision,
        "Test Mean Recall": mean_recall,
    }

    # Append per-class detailed results
    for cls in range(num_classes):
        test_results[f"Class {cls} PA"] = per_class_pa[cls]
        test_results[f"Class {cls} IoU"] = iou[cls]
        test_results[f"Class {cls} Dice Coefficient"] = dice[cls]
        test_results[f"Class {cls} Precision"] = precision[cls]
        test_results[f"Class {cls} Recall"] = recall[cls]

    # Print results
    for metric, value in test_results.items():
        print(f'{metric}: {value:.4f}')

    return test_results
