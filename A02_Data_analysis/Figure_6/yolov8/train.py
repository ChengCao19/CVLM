from pathlib import Path
import yaml
from ultralytics import YOLO


def validate_config(hyp):
    """验证关键参数有效性"""
    assert Path(hyp['pretrained_model']).exists(), "预训练模型不存在"
    assert hyp['imgsz'] % 32 == 0, "图像尺寸必须是32的倍数"
    assert 0 < hyp['lr0'] < 1, "学习率应在0-1之间"
    return hyp


def main():
    try:
        # 加载配置文件
        with open(r"D:\ProjectAll\yolov8\config\hyperparameters.yaml", encoding='utf-8') as f:
            hyp = yaml.safe_load(f)

        # 参数验证
        hyp = validate_config(hyp)
        print("✅ 加载配置成功")

        # 初始化模型
        model = YOLO(hyp['pretrained_model'])
        print(f"✅ 加载预训练模型: {Path(hyp['pretrained_model']).name}")

        # 执行训练（移除了冻结参数）
        results = model.train(
        ** {k: v for k, v in hyp.items() if k != 'pretrained_model'},  # 移除了freeze相关过滤
             data = r"D:\ProjectAll\yolov8\data\dataset.yaml",
        )

        # 输出最佳指标
        print("\n🏆 训练完成，最佳模型指标:")
        print(f"mAP50: {results.box.map50:.4f}")
        print(f"mAP50-95: {results.box.map:.4f}")
        print(f"模型保存路径: {results.save_dir}")

    except Exception as e:
        print(f"❌ 发生错误: {str(e)}")


if __name__ == "__main__":
    main()