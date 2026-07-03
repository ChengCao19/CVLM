# scripts/train.py

import os
import torch
import torch.nn as nn
from tqdm import tqdm
from torch.utils.tensorboard import SummaryWriter
from torch.cuda.amp import GradScaler, autocast
import logging
import time
import math


def calculate_metrics(preds, targets, num_classes):
    """
    Calculate pixel-level accuracy and per-class IoU.

    Args:
        preds (torch.Tensor): Model predictions with shape (batch_size, num_classes, H, W).
        targets (torch.Tensor): Ground-truth labels with shape (batch_size, H, W).
        num_classes (int): Number of classes.

    Returns:
        pixel_accuracy (float): Overall pixel accuracy.
        ious (list): Per-class IoU values.
    """
    preds = torch.argmax(preds, dim=1)  # Select the class with the highest probability
    correct = (preds == targets).sum().item()
    total = targets.numel()
    pixel_accuracy = correct / total

    ious = []
    for cls in range(num_classes):
        pred_inds = (preds == cls)
        target_inds = (targets == cls)
        intersection = (pred_inds & target_inds).sum().item()
        union = (pred_inds | target_inds).sum().item()
        if union == 0:
            iou = float('nan')  # Ignore classes that do not appear in the current batch
        else:
            iou = intersection / union
        ious.append(iou)

    return pixel_accuracy, ious


def train_model(model, train_loader, val_loader, criterion, optimizer, device, num_epochs, log_dir):
    """
    Train and validate the model.

    Args:
        model (torch.nn.Module): Model to be trained.
        train_loader (DataLoader): Training set DataLoader.
        val_loader (DataLoader): Validation set DataLoader.
        criterion (torch.nn.Module): Loss function.
        optimizer (torch.optim.Optimizer): Optimizer.
        device (torch.device): Computation device.
        num_epochs (int): Total number of training epochs.
        log_dir (str): TensorBoard log directory.
    """
    # Logging is assumed to be configured by the caller (main.py).
    # Do not reconfigure logging here to avoid conflicts.
    logger = logging.getLogger(__name__)
    logger.info('Starting training process')

    writer = SummaryWriter(log_dir=log_dir)
    scaler = GradScaler()
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(
        optimizer, mode='min', factor=0.1, patience=5, verbose=True
    )

    best_val_loss = float('inf')
    num_classes = None  # Will be inferred from the first forward pass

    try:
        for epoch in range(num_epochs):
            # ------------------- Training phase -------------------
            model.train()
            running_loss = 0.0
            running_accuracy = 0.0
            running_ious = None  # Will be initialized after num_classes is known
            total_batches = 0

            train_progress = tqdm(train_loader, desc=f'Epoch {epoch + 1}/{num_epochs} - Training', leave=False)
            for images, masks in train_progress:
                images = images.to(device)
                masks = masks.to(device)

                optimizer.zero_grad()
                try:
                    with autocast():
                        outputs = model(images)
                        if isinstance(outputs, dict) and 'out' in outputs:
                            outputs = outputs['out']
                        elif isinstance(outputs, tuple) and 'out' in outputs[0]:
                            outputs = outputs[0]['out']
                        loss = criterion(outputs, masks)
                except Exception as e:
                    logger.error(f'Error during forward pass or loss computation: {e}')
                    continue

                scaler.scale(loss).backward()
                # Gradient clipping
                torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
                scaler.step(optimizer)
                scaler.update()

                running_loss += loss.item()
                pixel_acc, ious = calculate_metrics(outputs, masks, num_classes=num_classes or outputs.size(1))
                running_accuracy += pixel_acc

                # Initialize running_ious on the first batch
                if running_ious is None:
                    num_classes = outputs.size(1)
                    running_ious = [0.0] * num_classes

                # Safely accumulate IoU (skip NaN values to avoid propagation)
                for i, iou in enumerate(ious):
                    if not math.isnan(iou):
                        running_ious[i] += iou
                total_batches += 1

                train_progress.set_postfix(
                    loss=running_loss / total_batches,
                    accuracy=running_accuracy / total_batches
                )

            epoch_loss = running_loss / total_batches
            epoch_accuracy = running_accuracy / total_batches
            # Compute mean IoU per class; count only valid (non-NaN) values
            epoch_ious = []
            for iou_sum in running_ious:
                # Here we simply divide by total_batches; NaN-safe accumulation is handled above.
                epoch_ious.append(iou_sum / total_batches)

            writer.add_scalar('Loss/Train', epoch_loss, epoch)
            writer.add_scalar('Accuracy/Train', epoch_accuracy, epoch)
            for i in range(num_classes):
                writer.add_scalar(f'IoU/Train_Class_{i}', epoch_ious[i], epoch)

            # ------------------- Validation phase -------------------
            model.eval()
            val_loss = 0.0
            val_accuracy = 0.0
            val_ious = None
            val_total_batches = 0

            val_progress = tqdm(val_loader, desc=f'Epoch {epoch + 1}/{num_epochs} - Validation', leave=False)
            with torch.no_grad():
                for images, masks in val_progress:
                    images = images.to(device)
                    masks = masks.to(device)

                    try:
                        outputs = model(images)
                        if isinstance(outputs, dict) and 'out' in outputs:
                            outputs = outputs['out']
                        elif isinstance(outputs, tuple) and 'out' in outputs[0]:
                            outputs = outputs[0]['out']
                        loss = criterion(outputs, masks)
                    except Exception as e:
                        logger.error(f'Error during forward pass or loss computation: {e}')
                        continue

                    val_loss += loss.item()
                    pixel_acc, ious = calculate_metrics(outputs, masks, num_classes=num_classes)
                    val_accuracy += pixel_acc

                    if val_ious is None:
                        val_ious = [0.0] * num_classes

                    for i, iou in enumerate(ious):
                        if not math.isnan(iou):
                            val_ious[i] += iou
                    val_total_batches += 1

                    val_progress.set_postfix(
                        loss=val_loss / val_total_batches,
                        accuracy=val_accuracy / val_total_batches
                    )

            val_epoch_loss = val_loss / val_total_batches
            val_epoch_accuracy = val_accuracy / val_total_batches
            val_epoch_ious = [iou_sum / val_total_batches for iou_sum in val_ious]

            writer.add_scalar('Loss/Validation', val_epoch_loss, epoch)
            writer.add_scalar('Accuracy/Validation', val_epoch_accuracy, epoch)
            for i in range(num_classes):
                writer.add_scalar(f'IoU/Validation_Class_{i}', val_epoch_ious[i], epoch)

            # Update learning-rate scheduler
            scheduler.step(val_epoch_loss)

            # Console output
            logger.info(
                f'Epoch {epoch + 1}/{num_epochs}, '
                f'Training Loss: {epoch_loss:.4f}, Training Accuracy: {epoch_accuracy:.4f}, '
                f'Validation Loss: {val_epoch_loss:.4f}, Validation Accuracy: {val_epoch_accuracy:.4f}'
            )
            print(
                f'Epoch {epoch + 1}/{num_epochs}, '
                f'Training Loss: {epoch_loss:.4f}, Training Accuracy: {epoch_accuracy:.4f}, '
                f'Validation Loss: {val_epoch_loss:.4f}, Validation Accuracy: {val_epoch_accuracy:.4f}'
            )

            # Save the best model
            if val_epoch_loss < best_val_loss:
                best_val_loss = val_epoch_loss
                best_model_path = os.path.join(log_dir, 'best_model.pth')
                try:
                    torch.save(model.state_dict(), best_model_path)
                    logger.info('Best model saved.')
                    print('Best model saved.')
                except Exception as e:
                    logger.error(f'Error saving the best model: {e}')
    except Exception as e:
        logger.error(f'Unexpected error during training: {e}')
    finally:
        writer.close()
        logger.info('Training process completed and SummaryWriter closed.')
