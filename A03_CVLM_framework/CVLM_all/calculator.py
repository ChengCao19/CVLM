import numpy as np


class ParameterCalculator:
    @staticmethod
    def calc_area_params(mask):
        h, w = mask.shape
        total = h * w
        leaf_pixels = int(np.sum(mask > 0))
        la = leaf_pixels
        lar = leaf_pixels / total if total > 0 else 0.0
        return la, lar

    @staticmethod
    def calc_shape_params(boxes, view_type="TVDs"):
        if not boxes:
            return None
        best = max(boxes, key=lambda x: x["conf"])
        x1, y1, x2, y2 = best["bbox"]
        width = x2 - x1
        height = y2 - y1

        if view_type == "TVDs":
            ratio = width / height if height > 0 else 0.0
        else:
            ratio = height / width if width > 0 else 0.0

        centroid = ((x1 + x2) / 2.0, (y1 + y2) / 2.0)
        return {
            "ratio": ratio,
            "centroid": centroid,
            "width": width,
            "height": height
        }

    @staticmethod
    def calc_velocity(values, timestamps):
        if len(values) < 2:
            return [0.0]
        velocities = [0.0]
        for i in range(1, len(values)):
            dt = (timestamps[i] - timestamps[i - 1]).total_seconds()
            if dt > 0:
                v = (values[i] - values[i - 1]) / dt
            else:
                v = 0.0
            velocities.append(v)
        return velocities
