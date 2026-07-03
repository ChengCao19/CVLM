import os
import argparse
import logging
from scripts.data_preprocessing import convert_labelme_to_mask
from scripts.utils import split_dataset
from scripts.dataset import SegmentationDataset
from scripts.model import get_model
from scripts.train import train_model
from scripts.test import test_model
from torch.utils.data import DataLoader
from torchvision import transforms
import torch
import torch.nn as nn
from PIL import Image


def get_dataloaders(data_dir, batch_size=4, num_workers=4):
    """
    Create DataLoaders for training, validation, and testing.

    Args:
        data_dir (str): Root directory of the split dataset.
        batch_size (int): Batch size.
        num_workers (int): Number of worker threads for DataLoader.

    Returns:
        tuple: (train_loader, val_loader, test_loader)
    """
    transform = transforms.Compose([
        transforms.Resize((512, 512)),  # Adjust according to your needs
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406],  # ImageNet mean
                             std=[0.229, 0.224, 0.225])  # ImageNet std
    ])

    target_transform = transforms.Compose([
        transforms.Resize((512, 512), interpolation=Image.NEAREST)
    ])

    train_dataset = SegmentationDataset(
        image_dir=os.path.join(data_dir, 'train', 'image'),
        mask_dir=os.path.join(data_dir, 'train', 'label'),
        transform=transform,
        target_transform=target_transform
    )

    val_dataset = SegmentationDataset(
        image_dir=os.path.join(data_dir, 'val', 'image'),
        mask_dir=os.path.join(data_dir, 'val', 'label'),
        transform=transform,
        target_transform=target_transform
    )

    test_dataset = SegmentationDataset(
        image_dir=os.path.join(data_dir, 'test', 'image'),
        mask_dir=os.path.join(data_dir, 'test', 'label'),
        transform=transform,
        target_transform=target_transform
    )

    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        drop_last=True  # Ensure every batch has the same number of samples
    )
    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers
    )
    test_loader = DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers
    )

    return train_loader, val_loader, test_loader


def save_test_results(test_results, log_dir):
    """
    Save test metrics to a text file.
    """
    test_results_path = os.path.join(log_dir, 'test_results.txt')

    with open(test_results_path, 'w') as f:
        f.write("Test Results\n")
        f.write("=====================\n")
        for metric, value in test_results.items():
            f.write(f"{metric}: {value:.4f}\n")
        f.write("=====================\n")


def setup_logging(log_dir):
    """
    Configure logging to write to a file.
    """
    logging.basicConfig(
        filename=os.path.join(log_dir, 'training.log'),
        filemode='a',
        format='%(asctime)s - %(levelname)s - %(message)s',
        level=logging.INFO
    )
    logging.info('Logging started.')


def main():
    parser = argparse.ArgumentParser(description='DeepLabv3+ Leaf Segmentation')
    parser.add_argument('--json_dir', type=str, default=r'D:\ProjectAll\new_1\datasets\label',
                        help='Directory containing LabelMe JSON annotations')
    parser.add_argument('--image_dir', type=str, default=r'D:\ProjectAll\new_1\datasets\image',
                        help='Directory containing input images')
    parser.add_argument('--mask_dir', type=str, default=r'D:\ProjectAll\new_1\datasets\mask',
                        help='Directory to save generated masks')
    parser.add_argument('--split_output_dir', type=str, default=r'D:\ProjectAll\new_1\datasets\split',
                        help='Output directory for the split dataset')
    parser.add_argument('--log_dir', type=str, default=r'D:\ProjectAll\new_1\logs',
                        help='TensorBoard log directory')
    parser.add_argument('--num_classes', type=int, default=2,
                        help='Number of classes, including background and leaf')
    parser.add_argument('--batch_size', type=int, default=4, help='Batch size')
    parser.add_argument('--num_workers', type=int, default=4, help='Number of DataLoader workers')
    parser.add_argument('--num_epochs', type=int, default=100, help='Total number of training epochs')
    parser.add_argument('--learning_rate', type=float, default=1e-4, help='Learning rate')

    args = parser.parse_args()

    # Configuration parameters
    json_dir = args.json_dir
    image_dir = args.image_dir
    mask_dir = args.mask_dir
    split_output_dir = args.split_output_dir
    num_classes = args.num_classes
    batch_size = args.batch_size
    num_workers = args.num_workers
    num_epochs = args.num_epochs
    learning_rate = args.learning_rate
    log_dir = args.log_dir
    model_save_path = os.path.join(log_dir, 'best_model.pth')  # Fixed filename for the best model

    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f'Using device: {device}')

    # Setup logging (only once; downstream modules should reuse this logger)
    setup_logging(log_dir)
    logger = logging.getLogger(__name__)

    # Label-to-class-ID mapping
    label_to_id = {'background': 0, 'leaf': 1}  # Only background and leaf

    # 1. Convert JSON annotations to masks
    print('Converting JSON annotations to mask images...')
    logger.info('Converting JSON annotations to mask images...')
    convert_labelme_to_mask(json_dir, mask_dir, label_to_id)

    # 2. Split the dataset
    print('Splitting dataset into train, val, and test...')
    logger.info('Splitting dataset into train, val, and test...')
    split_dataset(image_dir, mask_dir, split_output_dir)

    # 3. Create DataLoaders
    print('Creating DataLoaders...')
    logger.info('Creating DataLoaders...')
    train_loader, val_loader, test_loader = get_dataloaders(split_output_dir, batch_size, num_workers)

    # Verify batch shapes
    print('Verifying DataLoader outputs...')
    logger.info('Verifying DataLoader outputs...')
    for images, masks in train_loader:
        print(f'Train batch - images shape: {images.shape}, masks shape: {masks.shape}')
        break
    for images, masks in val_loader:
        print(f'Validation batch - images shape: {images.shape}, masks shape: {masks.shape}')
        break
    for images, masks in test_loader:
        print(f'Test batch - images shape: {images.shape}, masks shape: {masks.shape}')
        break

    # 4. Initialize model
    print('Initializing model...')
    logger.info('Initializing model...')
    model = get_model(num_classes)
    model = model.to(device)

    # 5. Define loss function and optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)

    # 6. Train the model
    print('Starting training...')
    logger.info('Starting training...')
    train_model(model, train_loader, val_loader, criterion, optimizer, device, num_epochs, log_dir)

    # 7. Load the best model
    print('Loading best model for testing...')
    logger.info('Loading best model for testing...')
    model.load_state_dict(torch.load(model_save_path))

    # 8. Evaluate on the test set
    print('Evaluating on test set...')
    logger.info('Evaluating on test set...')
    test_results = test_model(model, test_loader, device, num_classes)

    # Save test results
    save_test_results(test_results, log_dir)

    print('Training and evaluation complete.')
    logger.info('Training and evaluation complete.')


if __name__ == '__main__':
    main()
