# scripts/predict_gui.py

import torch
from torchvision import transforms
from PIL import Image
import matplotlib.pyplot as plt
import numpy as np
import os
import tkinter as tk
from tkinter import filedialog, messagebox
from tkinter import ttk

# Import model definition; adjust the import path if your package structure differs.
from scripts.model import get_model


def load_model(model_path, num_classes, device):
    """
    Load a trained model from disk.

    Args:
        model_path (str): Path to the saved model weights (.pth/.pt).
        num_classes (int): Number of output classes.
        device (torch.device): Target device.

    Returns:
        model (torch.nn.Module): Model in evaluation mode.
    """
    model = get_model(num_classes)
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.to(device)
    model.eval()
    return model


def preprocess_image(image_path, transform):
    """
    Preprocess an input image for model inference.

    Args:
        image_path (str): Path to the image file.
        transform (callable): torchvision transform pipeline.

    Returns:
        torch.Tensor: Transformed image tensor.
    """
    image = Image.open(image_path).convert('RGB')
    image = transform(image)
    return image


def postprocess_output(output):
    """
    Convert raw model logits into a discrete prediction mask.

    Args:
        output (torch.Tensor): Model output of shape (B, C, H, W).

    Returns:
        np.ndarray: Predicted label map of shape (B, H, W).
    """
    preds = torch.argmax(output, dim=1).cpu().numpy()
    return preds


def visualize_prediction(image_path, prediction, save_dir):
    """
    Visualize the prediction as an overlay on the original image and save the results.

    Args:
        image_path (str): Path to the original image.
        prediction (np.ndarray): Predicted mask of shape (H, W).
        save_dir (str): Directory where outputs will be saved.

    Returns:
        tuple: (visualization_path, mask_path)
    """
    image = Image.open(image_path).convert('RGB')
    image = image.resize((prediction.shape[1], prediction.shape[0]))

    base_name = os.path.basename(image_path)
    name, ext = os.path.splitext(base_name)
    visualization_path = os.path.join(save_dir, f"{name}_visualization.png")
    mask_path = os.path.join(save_dir, f"{name}_mask.png")

    plt.figure(figsize=(12, 6))

    # Original image
    plt.subplot(1, 2, 1)
    plt.imshow(image)
    plt.title('Original Image', fontsize=14)
    plt.axis('off')

    # Overlay prediction
    plt.subplot(1, 2, 2)
    plt.imshow(image)
    plt.imshow(prediction, cmap='jet', alpha=0.5)
    plt.title('Predicted Mask', fontsize=14)
    plt.axis('off')

    plt.savefig(visualization_path, bbox_inches='tight')
    plt.close()

    # Save the binary mask as a color image (leaf = red)
    mask_color = np.zeros((prediction.shape[0], prediction.shape[1], 3), dtype=np.uint8)
    mask_color[prediction == 1] = [255, 0, 0]  # Leaf region in red
    mask_image = Image.fromarray(mask_color)
    mask_image.save(mask_path)

    return visualization_path, mask_path


class PredictGUI:
    def __init__(self, master):
        self.master = master
        master.title("Image Segmentation Prediction Tool")
        master.geometry("800x500")
        master.resizable(True, True)

        # Style configuration
        style = ttk.Style()
        style.theme_use('clam')
        style.configure("TButton", padding=6)
        style.configure("TLabel", padding=6, font=('Helvetica', 12))
        style.configure("Header.TLabel", font=('Helvetica', 14, 'bold'))
        style.configure("TProgressbar", thickness=20)

        # Main frame
        main_frame = ttk.Frame(master, padding="20 20 20 20")
        main_frame.pack(fill=tk.BOTH, expand=True)
        main_frame.columnconfigure(1, weight=1)

        # Model selection
        model_label = ttk.Label(main_frame, text="Select Model File:", style="Header.TLabel")
        model_label.grid(row=0, column=0, sticky=tk.W, pady=10)

        self.model_path = tk.StringVar()
        self.model_entry = ttk.Entry(main_frame, textvariable=self.model_path, width=60)
        self.model_entry.grid(row=0, column=1, sticky=tk.EW, pady=10, padx=5)
        self.browse_model_btn = ttk.Button(main_frame, text="Browse", command=self.browse_model)
        self.browse_model_btn.grid(row=0, column=2, sticky=tk.W, pady=10)

        # Image selection
        image_label = ttk.Label(main_frame, text="Select Image File(s) or Folder:", style="Header.TLabel")
        image_label.grid(row=1, column=0, sticky=tk.W, pady=10)

        self.image_paths = []
        self.image_entry = ttk.Entry(main_frame, width=60)
        self.image_entry.grid(row=1, column=1, sticky=tk.EW, pady=10, padx=5)
        self.browse_image_btn = ttk.Button(main_frame, text="Browse", command=self.browse_images)
        self.browse_image_btn.grid(row=1, column=2, sticky=tk.W, pady=10)

        # Save directory selection
        save_label = ttk.Label(main_frame, text="Select Output Directory:", style="Header.TLabel")
        save_label.grid(row=2, column=0, sticky=tk.W, pady=10)

        self.save_dir = tk.StringVar()
        self.save_entry = ttk.Entry(main_frame, textvariable=self.save_dir, width=60)
        self.save_entry.grid(row=2, column=1, sticky=tk.EW, pady=10, padx=5)
        self.browse_save_btn = ttk.Button(main_frame, text="Browse", command=self.browse_save_dir)
        self.browse_save_btn.grid(row=2, column=2, sticky=tk.W, pady=10)

        # Device selection
        device_label = ttk.Label(main_frame, text="Select Device:", style="Header.TLabel")
        device_label.grid(row=3, column=0, sticky=tk.W, pady=10)

        device_frame = ttk.Frame(main_frame)
        device_frame.grid(row=3, column=1, sticky=tk.W, pady=10, padx=5)

        self.device = tk.StringVar(value='cuda' if torch.cuda.is_available() else 'cpu')
        self.gpu_radio = ttk.Radiobutton(device_frame, text='GPU (cuda)', variable=self.device, value='cuda')
        self.gpu_radio.pack(side=tk.LEFT, padx=10)
        self.cpu_radio = ttk.Radiobutton(device_frame, text='CPU', variable=self.device, value='cpu')
        self.cpu_radio.pack(side=tk.LEFT, padx=10)

        # Predict button
        self.predict_btn = ttk.Button(main_frame, text="Start Prediction", command=self.run_prediction)
        self.predict_btn.grid(row=4, column=1, pady=20)

        # Progress bar
        self.progress = ttk.Progressbar(main_frame, orient=tk.HORIZONTAL, length=600, mode='determinate')
        self.progress.grid(row=5, column=0, columnspan=3, pady=10)

        # Status label
        self.status_var = tk.StringVar()
        self.status_label = ttk.Label(main_frame, textvariable=self.status_var, foreground='blue')
        self.status_label.grid(row=6, column=0, columnspan=3, pady=10)

    def browse_model(self):
        file_path = filedialog.askopenfilename(
            title="Select Model File",
            filetypes=[("PyTorch Model", "*.pth *.pt"), ("All Files", "*.*")]
        )
        if file_path:
            self.model_path.set(file_path)

    def browse_images(self):
        choice = messagebox.askquestion("Selection Type", "Select multiple files or a folder?", icon='question')
        if choice == 'yes':
            files = filedialog.askopenfilenames(
                title="Select Image Files",
                filetypes=[("Image Files", "*.jpg *.jpeg *.png"), ("All Files", "*.*")]
            )
            if files:
                self.image_paths = list(files)
                self.image_entry.delete(0, tk.END)
                self.image_entry.insert(0, f"Selected {len(files)} file(s)")
        else:
            folder = filedialog.askdirectory(title="Select Image Folder")
            if folder:
                files = [
                    os.path.join(folder, f)
                    for f in os.listdir(folder)
                    if f.lower().endswith(('.jpg', '.jpeg', '.png'))
                ]
                self.image_paths = files
                self.image_entry.delete(0, tk.END)
                self.image_entry.insert(0, f"Selected {len(files)} file(s)")

    def browse_save_dir(self):
        folder = filedialog.askdirectory(title="Select Save Directory")
        if folder:
            self.save_dir.set(folder)

    def run_prediction(self):
        model_path = self.model_path.get()
        save_dir = self.save_dir.get()
        device_str = self.device.get()

        if not model_path:
            messagebox.showerror("Error", "Please select a model file first.")
            return
        if not self.image_paths:
            messagebox.showerror("Error", "Please select image file(s) or a folder first.")
            return
        if not save_dir:
            messagebox.showerror("Error", "Please select an output directory first.")
            return

        device = torch.device(device_str if torch.cuda.is_available() and device_str == 'cuda' else 'cpu')
        self.status_var.set(f"Using device: {device}")
        self.master.update_idletasks()

        try:
            self.status_var.set("Loading model...")
            self.master.update_idletasks()
            # num_classes must match the value used during training.
            model = load_model(model_path, num_classes=2, device=device)
            self.status_var.set("Model loaded.")
            self.master.update_idletasks()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load model: {e}")
            self.status_var.set("Model loading failed.")
            return

        transform = transforms.Compose([
            transforms.Resize((512, 512)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                 std=[0.229, 0.224, 0.225])
        ])

        total = len(self.image_paths)
        self.progress['maximum'] = total
        self.progress['value'] = 0
        self.status_var.set("Starting prediction...")
        self.master.update_idletasks()

        for idx, image_path in enumerate(self.image_paths, 1):
            try:
                self.status_var.set(f"Preprocessing: {os.path.basename(image_path)}")
                self.master.update_idletasks()
                input_image = preprocess_image(image_path, transform)
                input_image = input_image.unsqueeze(0).to(device)

                self.status_var.set(f"Predicting: {os.path.basename(image_path)}")
                self.master.update_idletasks()
                with torch.no_grad():
                    output = model(input_image)['out']

                prediction = postprocess_output(output)

                self.status_var.set(f"Saving results: {os.path.basename(image_path)}")
                self.master.update_idletasks()
                visualization_path, mask_path = visualize_prediction(image_path, prediction[0], save_dir)

                print(f"Results saved to: {visualization_path} and {mask_path}")
            except Exception as e:
                print(f"Error processing {image_path}: {e}")
                messagebox.showwarning("Warning", f"Error processing {os.path.basename(image_path)}: {e}")
                continue
            finally:
                self.progress['value'] = idx
                self.master.update_idletasks()

        self.status_var.set("All predictions completed.")
        messagebox.showinfo("Done", "All predictions completed.")
        self.progress['value'] = 0


def main():
    root = tk.Tk()
    gui = PredictGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
