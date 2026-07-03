import os
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext
import ttkbootstrap as ttk
from ttkbootstrap.constants import *
import torch
import cv2

import config
from io_manager import ImageSequence
from model_loader import find_weight_file, load_segmentation_model, load_detection_model
from inference_engine import SegmentationEngine, DetectionEngine
from calculator import ParameterCalculator
from visualizer import create_mask_overlay, create_trajectory_overlay, create_trajectory_vector
from exporter import export_to_excel


class CVLMGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("CVLM")
        self.root.geometry("1280x850")

        self.folder_list = []
        self.cancelled = False
        self.processing = False

        self._build_ui()

    def _build_ui(self):
        hdr = ttk.Frame(self.root)
        hdr.pack(pady=10)
        ttk.Label(hdr, text="CVLM", font=("Helvetica", 32, "bold"), bootstyle="primary").pack()
        ttk.Label(hdr, text="Leaf Movement Parameter Extraction System",
                   font=("Helvetica", 12), bootstyle="secondary").pack()

        paned = ttk.Panedwindow(self.root, orient=HORIZONTAL)
        paned.pack(fill=BOTH, expand=True, padx=15, pady=10)

        left = ttk.Labelframe(paned, text="Dataset Selection", padding=10, bootstyle="info")
        paned.add(left, weight=1)

        vf = ttk.Frame(left)
        vf.pack(fill=X, pady=5)
        ttk.Label(vf, text="View Type:", font=("Helvetica", 10, "bold")).pack(side=LEFT)
        self.view_var = tk.StringVar(value="TVDs")
        ttk.Radiobutton(vf, text="TVDs", variable=self.view_var, value="TVDs").pack(side=LEFT, padx=10)
        ttk.Radiobutton(vf, text="SVDs", variable=self.view_var, value="SVDs").pack(side=LEFT, padx=10)

        bf = ttk.Frame(left)
        bf.pack(fill=X, pady=5)
        ttk.Button(bf, text="Add Folder", command=self.add_folder, bootstyle="success").pack(side=LEFT, padx=3)
        ttk.Button(bf, text="Remove", command=self.remove_folder, bootstyle="warning").pack(side=LEFT, padx=3)
        ttk.Button(bf, text="Clear", command=self.clear_folders, bootstyle="danger").pack(side=LEFT, padx=3)

        self.lb = tk.Listbox(left, height=18, selectmode=tk.EXTENDED, font=("Consolas", 10))
        self.lb.pack(fill=BOTH, expand=True, pady=5)

        ttk.Label(left, text="Each folder = one time-series of single-leaf images",
                  bootstyle="secondary", wraplength=350).pack(pady=5)

        right = ttk.Frame(paned, padding=5)
        paned.add(right, weight=2)

        mc = ttk.Labelframe(right, text="Model Configuration", padding=10, bootstyle="primary")
        mc.pack(fill=X, pady=5)

        mmf = ttk.Frame(mc)
        mmf.pack(fill=X)
        ttk.Label(mmf, text="Mode:", font=("Helvetica", 10, "bold")).pack(side=LEFT)
        self.model_mode = tk.StringVar(value="default")
        ttk.Radiobutton(mmf, text="Default", variable=self.model_mode, value="default",
                         command=self.toggle_model_mode).pack(side=LEFT, padx=10)
        ttk.Radiobutton(mmf, text="Custom", variable=self.model_mode, value="custom",
                         command=self.toggle_model_mode).pack(side=LEFT, padx=10)

        self.custom_frame = ttk.Frame(mc)
        self.model_vars = {}
        rows = [
            ("TVDs_seg", "TVDs Segmentation (Deeplabv3+)"),
            ("TVDs_det", "TVDs Detection (YOLOv8-T)"),
            ("SVDs_seg", "SVDs Segmentation (U-Net)"),
            ("SVDs_det", "SVDs Detection (YOLOv8-S)")
        ]
        for key, label in rows:
            row = ttk.Frame(self.custom_frame)
            row.pack(fill=X, pady=2)
            ttk.Label(row, text=label, width=30).pack(side=LEFT)
            var = tk.StringVar()
            ent = ttk.Entry(row, textvariable=var, width=35)
            ent.pack(side=LEFT, fill=X, expand=True, padx=3)
            ttk.Button(row, text="Browse", width=8,
                      command=lambda k=key, v=var: self.browse_model(k, v)).pack(side=LEFT)
            self.model_vars[key] = var

        pf = ttk.Labelframe(right, text="Progress", padding=10, bootstyle="primary")
        pf.pack(fill=X, pady=10)

        ttk.Label(pf, text="Overall Progress").pack(anchor=W)
        self.overall_pb = ttk.Progressbar(pf, maximum=100, bootstyle="success-striped", length=500)
        self.overall_pb.pack(fill=X, pady=2)

        ttk.Label(pf, text="Current Sequence").pack(anchor=W)
        self.current_pb = ttk.Progressbar(pf, maximum=100, bootstyle="info-striped", length=500)
        self.current_pb.pack(fill=X, pady=2)

        self.status_lbl = ttk.Label(pf, text="Ready", bootstyle="info", font=("Helvetica", 10))
        self.status_lbl.pack(anchor=W, pady=5)

        cf = ttk.Frame(right)
        cf.pack(fill=X, pady=10)
        self.start_btn = ttk.Button(cf, text="Start Processing", command=self.start_processing,
                                     bootstyle="success", width=18)
        self.start_btn.pack(side=LEFT, padx=5)
        self.cancel_btn = ttk.Button(cf, text="Cancel", command=self.cancel_processing,
                                    bootstyle="danger", width=12, state=DISABLED)
        self.cancel_btn.pack(side=LEFT, padx=5)

        logf = ttk.Labelframe(self.root, text="System Log", padding=5, bootstyle="secondary")
        logf.pack(fill=BOTH, expand=False, padx=15, pady=5)
        self.log_txt = scrolledtext.ScrolledText(logf, height=12, state=DISABLED, font=("Consolas", 9))
        self.log_txt.pack(fill=BOTH, expand=True)

        self.toggle_model_mode()

    def toggle_model_mode(self):
        if self.model_mode.get() == "custom":
            self.custom_frame.pack(fill=X, pady=5)
        else:
            self.custom_frame.pack_forget()

    def add_folder(self):
        f = filedialog.askdirectory(title="Select Image Sequence Folder")
        if f:
            v = self.view_var.get()
            self.folder_list.append((f, v))
            self.lb.insert(END, f"[{v}] {os.path.basename(f)}")
            self.log(f"Added: {f} ({v})")

    def remove_folder(self):
        sel = self.lb.curselection()
        for i in reversed(sel):
            self.lb.delete(i)
            removed = self.folder_list.pop(i)
            self.log(f"Removed: {removed[0]}")

    def clear_folders(self):
        self.folder_list.clear()
        self.lb.delete(0, END)
        self.log("Cleared all folders.")

    def browse_model(self, key, var):
        p = filedialog.askopenfilename(
            title=f"Select {key} Model",
            filetypes=[("Model Files", "*.pt *.pth"), ("All Files", "*.*")]
        )
        if p:
            var.set(p)
            self.log(f"Model {key}: {p}")

    def log(self, msg):
        def _insert():
            self.log_txt.config(state=NORMAL)
            self.log_txt.insert(END, str(msg) + "\n")
            self.log_txt.see(END)
            self.log_txt.config(state=DISABLED)
        self.root.after(0, _insert)

    def cancel_processing(self):
        self.cancelled = True
        self.log("Cancellation requested.")

    def start_processing(self):
        if not self.folder_list:
            messagebox.showwarning("Warning", "Please add at least one folder.")
            return
        if self.model_mode.get() == "custom":
            for k in self.model_vars:
                if not self.model_vars[k].get():
                    messagebox.showwarning("Warning", f"Please select model: {k}")
                    return

        self.cancelled = False
        self.processing = True
        self.start_btn.config(state=DISABLED)
        self.cancel_btn.config(state=NORMAL)
        self.log("=" * 60)
        self.log("Starting CVLM Processing...")

        t = threading.Thread(target=self._process_all, daemon=True)
        t.start()

    def _process_all(self):
        try:
            device = "cuda" if torch.cuda.is_available() else "cpu"
            self.log(f"Device: {device}")

            out_root = os.path.join(os.getcwd(), config.OUTPUT_DIR)
            os.makedirs(out_root, exist_ok=True)

            tvd_all, svd_all = [], []
            total = len(self.folder_list)

            for idx, (folder, view) in enumerate(self.folder_list):
                if self.cancelled:
                    self.log("Cancelled by user.")
                    break

                self._update_status(f"Folder {idx + 1}/{total}: {os.path.basename(folder)}")
                self._update_overall((idx / max(total, 1)) * 100)

                self.log("\n" + f"--- Processing {view}: {folder} ---")

                seg_eng, det_eng = self._load_engines(view, device)
                if seg_eng is None or det_eng is None:
                    self.log("  Model loading failed, skipped.")
                    continue

                res = self._process_sequence(folder, view, seg_eng, det_eng, device, out_root)
                if view == "TVDs":
                    tvd_all.extend(res)
                else:
                    svd_all.extend(res)

                self._update_overall(((idx + 1) / max(total, 1)) * 100)

            if tvd_all or svd_all:
                excel = os.path.join(out_root, "CVLM_Results.xlsx")
                export_to_excel(tvd_all, svd_all, excel)
                self.log("\n" + f"Excel saved: {excel}")
                self._show_complete(out_root)
            else:
                self.log("No results generated.")

        except Exception as e:
            import traceback
            self.log(f"ERROR: {e}")
            self.log(traceback.format_exc())
        finally:
            self.processing = False
            self._reset_ui()

    def _load_engines(self, view, device):
        try:
            if self.model_mode.get() == "default":
                root = config.DEFAULT_TVD_MODEL_DIR if view == "TVDs" else config.DEFAULT_SVD_MODEL_DIR
                seg_name = config.DEFAULT_MODELS[view]["segmentation"]
                det_name = config.DEFAULT_MODELS[view]["detection"]

                seg_path = find_weight_file(os.path.join(root, seg_name))
                det_path = find_weight_file(os.path.join(root, det_name))

                if not seg_path:
                    self.log(f"  Default seg model not found in {os.path.join(root, seg_name)}")
                    return None, None
                if not det_path:
                    self.log(f"  Default det model not found in {os.path.join(root, det_name)}")
                    return None, None
            else:
                seg_path = self.model_vars[f"{view}_seg"].get()
                det_path = self.model_vars[f"{view}_det"].get()

            self.log(f"  Seg model: {seg_path}")
            self.log(f"  Det model: {det_path}")

            seg_model = load_segmentation_model(seg_path, config.DEFAULT_MODELS[view]["segmentation"], device)
            seg_eng = SegmentationEngine(seg_model, device, config.INPUT_SIZE)

            det_model = load_detection_model(det_path, device)
            det_eng = DetectionEngine(det_model, device)

            return seg_eng, det_eng

        except Exception as e:
            self.log(f"  Model load error: {e}")
            return None, None

    def _process_sequence(self, folder, view, seg_eng, det_eng, device, out_root):
        seq = ImageSequence(folder)
        n = len(seq)
        if n == 0:
            self.log("  No images found.")
            return []

        fname = os.path.basename(os.path.normpath(folder))
        rdir = os.path.join(out_root, f"{view}_{fname}")
        os.makedirs(rdir, exist_ok=True)
        os.makedirs(os.path.join(rdir, "mask_overlay"), exist_ok=True)
        os.makedirs(os.path.join(rdir, "trajectory_overlay"), exist_ok=True)
        os.makedirs(os.path.join(rdir, "trajectory_vector"), exist_ok=True)

        results = []
        timestamps = []
        centroids = []
        prev_centroid = None
        prev_ratio = 0.0

        for i, img_path in enumerate(seq.image_files):
            if self.cancelled:
                break

            self._update_current((i / max(n, 1)) * 100)
            self._update_status(f"{os.path.basename(img_path)} ({i + 1}/{n})")

            try:
                mask = seg_eng.predict(img_path)
                boxes = det_eng.predict(img_path)
            except Exception as e:
                self.log(f"    Error on {os.path.basename(img_path)}: {e}")
                if results:
                    last = results[-1].copy()
                    last["interpolated"] = True
                    last["timestamp"] = seq.timestamps[i].strftime("%Y-%m-%d %H:%M:%S") if seq.timestamps[i] else ""
                    results.append(last)
                    timestamps.append(seq.timestamps[i])
                    centroids.append(centroids[-1] if centroids else (0.0, 0.0))
                else:
                    rec = {
                        "folder": fname,
                        "view": view,
                        "filename": os.path.basename(img_path),
                        "timestamp": seq.timestamps[i].strftime("%Y-%m-%d %H:%M:%S") if seq.timestamps[i] else "",
                        "interpolated": True,
                        "centroid_x": 0.0,
                        "centroid_y": 0.0,
                    }
                    if view == "TVDs":
                        rec["2D-LA"] = 0
                        rec["2D-LAR"] = 0.0
                        rec["2D-LSR"] = 0.0
                    else:
                        rec["2D-VA"] = 0
                        rec["2D-VAR"] = 0.0
                        rec["2D-VSR"] = 0.0
                    results.append(rec)
                    timestamps.append(seq.timestamps[i])
                    centroids.append((0.0, 0.0))
                continue

            la, lar = ParameterCalculator.calc_area_params(mask)
            shape = ParameterCalculator.calc_shape_params(boxes, view)

            if shape is None:
                interpolated = True
                centroid = prev_centroid if prev_centroid is not None else (0.0, 0.0)
                ratio = prev_ratio
            else:
                interpolated = False
                centroid = shape["centroid"]
                ratio = shape["ratio"]
                prev_centroid = centroid
                prev_ratio = ratio

            centroids.append(centroid)

            base = os.path.splitext(os.path.basename(img_path))[0]
            mpath = os.path.join(rdir, "mask_overlay", f"{base}_mask.png")
            create_mask_overlay(img_path, mask, mpath)

            rec = {
                "folder": fname,
                "view": view,
                "filename": os.path.basename(img_path),
                "timestamp": seq.timestamps[i].strftime("%Y-%m-%d %H:%M:%S") if seq.timestamps[i] else "",
                "interpolated": interpolated
            }

            if view == "TVDs":
                rec["2D-LA"] = la
                rec["2D-LAR"] = lar
                rec["2D-LSR"] = ratio
            else:
                rec["2D-VA"] = la
                rec["2D-VAR"] = lar
                rec["2D-VSR"] = ratio

            rec["centroid_x"] = centroid[0]
            rec["centroid_y"] = centroid[1]
            results.append(rec)
            timestamps.append(seq.timestamps[i])

            self.log(f"    {os.path.basename(img_path)}: area={la}, ratio={ratio:.4f}")

        if len(results) > 1:
            if view == "TVDs":
                areas = [r["2D-LA"] for r in results]
                lars = [r["2D-LAR"] for r in results]
                ratios = [r["2D-LSR"] for r in results]
                av = ParameterCalculator.calc_velocity(areas, timestamps)
                arv = ParameterCalculator.calc_velocity(lars, timestamps)
                rv = ParameterCalculator.calc_velocity(ratios, timestamps)
                for i, r in enumerate(results):
                    r["2D-LAV"] = av[i]
                    r["2D-LARV"] = arv[i]
                    r["2D-LSRV"] = rv[i]
            else:
                areas = [r["2D-VA"] for r in results]
                vars_ = [r["2D-VAR"] for r in results]
                ratios = [r["2D-VSR"] for r in results]
                av = ParameterCalculator.calc_velocity(areas, timestamps)
                arv = ParameterCalculator.calc_velocity(vars_, timestamps)
                rv = ParameterCalculator.calc_velocity(ratios, timestamps)
                for i, r in enumerate(results):
                    r["2D-VAV"] = av[i]
                    r["2D-VARV"] = arv[i]
                    r["2D-VSRV"] = rv[i]

        if centroids:
            last_img = seq.image_files[-1]
            create_trajectory_overlay(
                last_img, centroids,
                os.path.join(rdir, "trajectory_overlay", "trajectory_overlay.png")
            )
            img0 = cv2.imread(seq.image_files[0])
            shape = img0.shape if img0 is not None else None
            create_trajectory_vector(
                centroids,
                os.path.join(rdir, "trajectory_vector", "trajectory.svg"),
                shape
            )
            self.log("  Trajectory maps saved.")

        self._update_current(100)
        return results

    def _update_status(self, text):
        self.root.after(0, lambda: self.status_lbl.config(text=text))

    def _update_overall(self, val):
        self.root.after(0, lambda: self.overall_pb.config(value=val))

    def _update_current(self, val):
        self.root.after(0, lambda: self.current_pb.config(value=val))

    def _reset_ui(self):
        def _do():
            self.start_btn.config(state=NORMAL)
            self.cancel_btn.config(state=DISABLED)
            self.status_lbl.config(text="Ready")
            self.overall_pb.config(value=0)
            self.current_pb.config(value=0)
        self.root.after(0, _do)

    def _show_complete(self, path):
        self.root.after(0, lambda: messagebox.showinfo(
            "Complete", "Processing finished." + "\n" + "Results saved to:" + "\n" + path
        ))