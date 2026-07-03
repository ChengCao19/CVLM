# scripts/data_preprocessing.py

import os
import json
from PIL import Image, ImageDraw
from tqdm import tqdm


def convert_labelme_to_mask(json_dir, mask_dir, label_to_id):
    """
    Convert LabelMe JSON annotation files into mask images.

    Args:
        json_dir (str): Directory containing JSON files.
        mask_dir (str): Directory to save the generated mask images.
        label_to_id (dict): Mapping from label names to class IDs.
    """
    if not os.path.exists(mask_dir):
        os.makedirs(mask_dir)

    json_files = [f for f in os.listdir(json_dir) if f.endswith('.json')]
    for json_file in tqdm(json_files, desc='Converting JSON to masks'):
        json_path = os.path.join(json_dir, json_file)
        with open(json_path, 'r') as f:
            data = json.load(f)

        img_height = data['imageHeight']
        img_width = data['imageWidth']
        mask = Image.new('L', (img_width, img_height), 0)  # 'L' mode: 8-bit grayscale
        draw = ImageDraw.Draw(mask)

        for shape in data['shapes']:
            label = shape['label']
            points = shape['points']
            class_id = label_to_id.get(label, 0)

            polygon = [tuple(point) for point in points]
            draw.polygon(polygon, outline=class_id, fill=class_id)

        mask_filename = os.path.splitext(json_file)[0] + '.png'
        mask_path = os.path.join(mask_dir, mask_filename)
        mask.save(mask_path)
