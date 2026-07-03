import os
import re
from datetime import datetime, timedelta
from PIL import Image
from PIL.ExifTags import TAGS


def extract_exif_datetime(image_path):
    try:
        img = Image.open(image_path)
        exif = img.getexif()
        if exif:
            for tag_id, value in exif.items():
                tag = TAGS.get(tag_id, tag_id)
                if tag in ("DateTimeOriginal", "DateTime", "DateTimeDigitized"):
                    return datetime.strptime(str(value), "%Y:%m:%d %H:%M:%S")
    except Exception:
        pass
    return None


def natural_sort_key(s):
    return [
        int(text) if text.isdigit() else text.lower()
        for text in re.split(r"([0-9]+)", os.path.basename(s))
    ]


def get_image_files(folder):
    if not os.path.isdir(folder):
        return []
    files = [
        f for f in os.listdir(folder)
        if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff'))
    ]
    files.sort(key=natural_sort_key)
    return [os.path.join(folder, f) for f in files]
