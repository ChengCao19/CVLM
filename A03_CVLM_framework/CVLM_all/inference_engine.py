import torch
import numpy as np
import cv2
from PIL import Image
from torchvision import transforms


class SegmentationEngine:
    def __init__(self, model, device, input_size=(512, 512)):
        self.model = model
        self.device = device
        self.input_size = input_size
        self.transform = transforms.Compose([
            transforms.Resize(input_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

    def predict(self, image_path):
        image = Image.open(image_path).convert("RGB")
        orig_w, orig_h = image.size
        input_tensor = self.transform(image).unsqueeze(0).to(self.device)

        with torch.no_grad():
            output = self.model(input_tensor)
            if isinstance(output, dict):
                output = output["out"]
            pred = torch.argmax(output, dim=1).squeeze(0).cpu().numpy()

        pred = cv2.resize(pred.astype(np.uint8), (orig_w, orig_h), interpolation=cv2.INTER_NEAREST)
        return pred


class DetectionEngine:
    def __init__(self, model, device):
        self.model = model
        self.device = device

    def predict(self, image_path):
        results = self.model(image_path, device=self.device, verbose=False)
        boxes = []
        for r in results:
            if r.boxes is not None:
                for box in r.boxes:
                    xyxy = box.xyxy[0].cpu().numpy()
                    conf = box.conf[0].cpu().numpy()
                    boxes.append({
                        "bbox": [float(x) for x in xyxy],
                        "conf": float(conf)
                    })
        return boxes
