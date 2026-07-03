from ultralytics import YOLO
import os
import csv
import pandas as pd
import matplotlib.pyplot as plt
import shutil
import cv2

# 新增可配置参数
CENTER_COLOR = (0, 255, 0)  # 中心点颜色 (BGR格式)，当前设置为绿色
CENTER_RADIUS = 10  # 中心点半径


def plot_metrics(metrics, output_dir):
    """兼容最新版YOLOv8的指标可视化"""
    plt.figure(figsize=(10, 6))
    plt.plot(metrics.box.maps)
    plt.xlabel('IoU Threshold')
    plt.ylabel('mAP')
    plt.title('mAP Curve')
    plt.savefig(os.path.join(output_dir, 'map_curve.png'))
    plt.close()


def main():
    # 路径配置
    test_images_dir = r'D:\ProjectAll\yolov8\data\images\test'
    model_path = r'D:\ProjectAll\yolov8\logs\leaf_exp\weights\best.pt'
    output_root = r'D:\ProjectAll\yolov8\test'
    dataset_yaml = r'D:\ProjectAll\yolov8\data\dataset.yaml'

    # 创建输出目录
    metrics_dir = os.path.join(output_root, 'metrics')
    plots_dir = os.path.join(output_root, 'visualizations')
    labels_dir = os.path.join(output_root, 'labels')
    os.makedirs(metrics_dir, exist_ok=True)
    os.makedirs(plots_dir, exist_ok=True)
    os.makedirs(labels_dir, exist_ok=True)

    # 加载模型
    model = YOLO(model_path)

    # 执行预测（禁用自动保存）
    results = model.predict(
        source=test_images_dir,
        save=False,
        imgsz=512,
        conf=0.25
    )

    # 处理每个检测结果
    csv_path = os.path.join(metrics_dir, 'detections.csv')
    with open(csv_path, 'w', newline='') as f:
        writer = csv.writer(f)
        # 修改列名更准确
        writer.writerow(['filename', 'x_center', 'y_center', 'width', 'height',
                         'confidence', 'class', 'width_height_ratio'])

        for result in results:
            filename = os.path.basename(result.path)

            # 处理图像绘制
            img_array = result.plot()  # 获取带检测框的RGB图像
            img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)

            # 保存标签文件
            txt_filename = os.path.splitext(filename)[0] + '.txt'
            txt_path = os.path.join(labels_dir, txt_filename)

            with open(txt_path, 'w') as f_txt:
                for box, conf, cls_id in zip(result.boxes.xywhn.cpu().numpy(),
                                             result.boxes.conf.cpu().numpy(),
                                             result.boxes.cls.cpu().numpy()):
                    # 计算宽高比（宽/长，保证长>宽）
                    w, h = box[2], box[3]
                    long = max(w, h)
                    short = min(w, h)
                    width_height_ratio = short / long  # 修改计算方式

                    # 写入CSV
                    writer.writerow([filename, *box, conf, int(cls_id), width_height_ratio])

                    # 写入标签文件
                    f_txt.write(f"{int(cls_id)} {box[0]} {box[1]} {box[2]} {box[3]} {conf}\n")

                    # 绘制中心点（使用可配置参数）
                    x_center_abs = int(result.orig_shape[1] * box[0])
                    y_center_abs = int(result.orig_shape[0] * box[1])
                    cv2.circle(img_array,
                               (x_center_abs, y_center_abs),
                               CENTER_RADIUS,
                               CENTER_COLOR,
                               -1)  # -1表示实心圆

            # 保存处理后的图像
            cv2.imwrite(os.path.join(plots_dir, filename), img_array)

    # 后续验证和指标处理保持不变...
    # 执行验证并获取指标
    metrics = model.val(
        data=dataset_yaml,
        split='test',
        plots=True,
        save_json=True
    )

    # 移动自动生成的图表
    val_plots_dir = os.path.join('runs', 'detect', 'val')
    if os.path.exists(val_plots_dir):
        for plot_file in os.listdir(val_plots_dir):
            src_path = os.path.join(val_plots_dir, plot_file)
            dst_path = os.path.join(plots_dir, plot_file)
            shutil.move(src_path, dst_path)
        shutil.rmtree(val_plots_dir)

    # 生成自定义图表
    plot_metrics(metrics, plots_dir)

    # 保存指标摘要
    pd.DataFrame({
        'mAP50': [metrics.box.map50],
        'mAP50-95': [metrics.box.map],
        'Precision': [metrics.box.p.mean()],
        'Recall': [metrics.box.r.mean()]
    }).to_csv(os.path.join(metrics_dir, 'metrics_summary.csv'), index=False)

    print(f"可视化结果保存在: {plots_dir}")


if __name__ == '__main__':
    main()