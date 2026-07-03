import cv2
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def create_mask_overlay(image_path, mask, save_path):
    img = cv2.imread(image_path)
    if img is None:
        return
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    overlay = img.copy()
    overlay[mask > 0] = [255, 0, 0]
    result = cv2.addWeighted(img, 1.0, overlay, 0.5, 0)
    cv2.imwrite(save_path, cv2.cvtColor(result, cv2.COLOR_RGB2BGR))


def create_trajectory_overlay(image_path, centroids, save_path):
    img = cv2.imread(image_path)
    if img is None:
        return
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    fig, ax = plt.subplots(figsize=(10, 10))
    ax.imshow(img)

    xs = [c[0] for c in centroids]
    ys = [c[1] for c in centroids]
    ax.plot(xs, ys, "y-", linewidth=2.5, label="Trajectory")

    for i, (x, y) in enumerate(centroids):
        color = "red" if i == len(centroids) - 1 else "yellow"
        ax.scatter(x, y, c=color, s=60, zorder=5, edgecolors="black", linewidths=0.5)

    ax.set_title("Leaf Motion Trajectory", fontsize=14)
    ax.axis("off")
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()


def create_trajectory_vector(centroids, save_path, image_shape=None):
    fig, ax = plt.subplots(figsize=(8, 8))
    xs = [c[0] for c in centroids]
    ys = [c[1] for c in centroids]

    if image_shape:
        h, w = image_shape[:2]
        ax.set_xlim(0, w)
        ax.set_ylim(h, 0)
    else:
        ax.invert_yaxis()

    ax.plot(xs, ys, "b-", linewidth=2, marker="o", markersize=5,
            markerfacecolor="white", markeredgewidth=1.5)
    ax.set_title("Trajectory Vector Map", fontsize=14)
    ax.set_xlabel("X (pixels)", fontsize=12)
    ax.set_ylabel("Y (pixels)", fontsize=12)
    ax.grid(True, alpha=0.3)
    ax.set_aspect("equal")

    plt.tight_layout()
    plt.savefig(save_path, format="svg", dpi=300, bbox_inches="tight")
    plt.close()
