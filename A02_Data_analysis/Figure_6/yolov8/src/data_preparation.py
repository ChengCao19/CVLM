import os
import json
import shutil
import random
from tqdm import tqdm

# 路径配置
RAW_IMAGE_DIR = r"D:\ProjectAll\yolov8\datasets\image"
RAW_LABEL_DIR = r"D:\ProjectAll\yolov8\datasets\label"
OUTPUT_ROOT = r"D:\ProjectAll\yolov8\data"
CLASS_NAME = "leaf"
IMG_SIZE = 1024
SPLIT_RATIO = (0.7, 0.2, 0.1)  # train/val/test
SEED = 2024


def convert_labelme_to_yolo():
    # 创建临时目录
    temp_img = os.path.join(OUTPUT_ROOT, "temp_images")
    temp_label = os.path.join(OUTPUT_ROOT, "temp_labels")
    os.makedirs(temp_img, exist_ok=True)
    os.makedirs(temp_label, exist_ok=True)

    # 获取有效文件对
    valid_pairs = []
    for img_name in os.listdir(RAW_IMAGE_DIR):
        if img_name.lower().endswith(('.png', '.jpg', '.jpeg')):
            base_name = os.path.splitext(img_name)[0]
            json_path = os.path.join(RAW_LABEL_DIR, f"{base_name}.json")
            if os.path.exists(json_path):
                valid_pairs.append((img_name, json_path))

    # 转换所有标注文件
    for img_name, json_path in tqdm(valid_pairs, desc="Converting labels"):
        # 复制图像到临时目录
        shutil.copy(os.path.join(RAW_IMAGE_DIR, img_name), temp_img)

        # 转换标签
        with open(json_path) as f:
            label_data = json.load(f)

        txt_name = os.path.splitext(img_name)[0] + ".txt"
        with open(os.path.join(temp_label, txt_name), "w") as f:
            for shape in label_data["shapes"]:
                if shape["label"] == CLASS_NAME and shape["shape_type"] == "rectangle":
                    x1, y1 = shape["points"][0]
                    x2, y2 = shape["points"][1]

                    # 计算归一化坐标
                    x_center = (x1 + x2) / 2 / IMG_SIZE
                    y_center = (y1 + y2) / 2 / IMG_SIZE
                    width = abs(x2 - x1) / IMG_SIZE
                    height = abs(y2 - y1) / IMG_SIZE

                    f.write(f"0 {x_center:.6f} {y_center:.6f} {width:.6f} {height:.6f}\n")

    return temp_img, temp_label


def split_dataset(temp_img, temp_label):
    # 获取所有基础文件名
    all_files = [os.path.splitext(f)[0] for f in os.listdir(temp_img)]
    random.shuffle(all_files)

    # 划分数据集
    total = len(all_files)
    train_end = int(total * SPLIT_RATIO[0])
    val_end = train_end + int(total * SPLIT_RATIO[1])

    splits = {
        "train": all_files[:train_end],
        "val": all_files[train_end:val_end],
        "test": all_files[val_end:]
    }

    # 移动文件到最终目录
    for split, files in splits.items():
        os.makedirs(os.path.join(OUTPUT_ROOT, "images", split), exist_ok=True)
        os.makedirs(os.path.join(OUTPUT_ROOT, "labels", split), exist_ok=True)

        for base_name in files:
            # 移动图像
            for ext in [".jpg", ".png", ".jpeg"]:
                src_img = os.path.join(temp_img, base_name + ext)
                if os.path.exists(src_img):
                    shutil.move(src_img, os.path.join(OUTPUT_ROOT, "images", split, base_name + ext))
                    break

            # 移动标签
            src_txt = os.path.join(temp_label, base_name + ".txt")
            shutil.move(src_txt, os.path.join(OUTPUT_ROOT, "labels", split, base_name + ".txt"))

    # 清理临时目录
    shutil.rmtree(temp_img)
    shutil.rmtree(temp_label)


if __name__ == "__main__":
    random.seed(SEED)
    temp_img, temp_label = convert_labelme_to_yolo()
    split_dataset(temp_img, temp_label)

    # 生成dataset.yaml
    dataset_yaml = f"""path: {OUTPUT_ROOT}
train: images/train
val: images/val
test: images/test

names:
  0: {CLASS_NAME}
"""
    with open(os.path.join(OUTPUT_ROOT, "dataset.yaml"), "w") as f:
        f.write(dataset_yaml)

    print("数据准备完成！")