import os
from datetime import datetime, timedelta
from utils import extract_exif_datetime, get_image_files


class ImageSequence:
    def __init__(self, folder_path):
        self.folder_path = folder_path
        self.folder_name = os.path.basename(os.path.normpath(folder_path))
        self.image_files = []
        self.timestamps = []
        self._load()

    def _load(self):
        self.image_files = get_image_files(self.folder_path)
        if not self.image_files:
            return

        for f in self.image_files:
            dt = extract_exif_datetime(f)
            self.timestamps.append(dt)

        for i in range(len(self.timestamps)):
            if self.timestamps[i] is None:
                if i == 0:
                    if len(self.timestamps) > 1 and self.timestamps[1] is not None:
                        self.timestamps[i] = self.timestamps[1] - timedelta(seconds=1)
                    else:
                        self.timestamps[i] = datetime.now()
                else:
                    self.timestamps[i] = self.timestamps[i - 1] + timedelta(seconds=1)

    def __len__(self):
        return len(self.image_files)
