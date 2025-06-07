#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#########################################################
# created : 2025/06/12 17:25                            #
# updated : 2025/06/07 17:05                            #
# purpose : track marker & dump (cx, cy) per frame      #
#########################################################

import cv2
import os
import sys
from typing import Tuple, List, Optional

# ------------------------------------------------------
# 預設批次清單：影片檔名 → (x, y, w, h)
# ------------------------------------------------------
# DEFAULT_JOBS with (x + 0, y − 80) applied to every entry
DEFAULT_JOBS: list[tuple[str, tuple[int, int, int, int]]] = [
    ("a.mp4", (575, 320, 100, 100)),
    ("b.mp4", (550, 345, 100, 100)),
    ("c.mp4", (575, 270, 100, 100)),
    ("d.mp4", (575, 295, 100, 100)),
    ("e.mp4", (610, 330, 100, 100)),
    ("f.mp4", (660, 270, 100, 100)),
    ("g.mp4", (585, 360, 100, 100)),
    ("h.mp4", (625, 300, 100, 100)),
    ("i.mp4", (590, 300, 100, 100)),
    ("j.mp4", (620, 290, 100, 100)),
    ("k.mp4", (605, 300, 100, 100)),
    ("l.mp4", (580, 460, 100, 100)),
    ("m.mp4", (565, 395, 100, 100)),
    ("n.mp4", (560, 390, 100, 100)),
    ("o.mp4", (620, 340, 100, 100)),
    ("p.mp4", (620, 340, 100, 100)),
    ("q.mp4", (605, 340, 100, 100)),
    ("r.mp4", (605, 315, 100, 100)),
    ("s.mp4", (670, 315, 100, 100)),
    ("t.mp4", (635, 280, 100, 100)),
    ("u.mp4", (600, 305, 100, 100)),
]


# ------------------------------------------------------
# 單支影片處理流程
# ------------------------------------------------------
def process_video(video_path: str,
                  init_box: Optional[Tuple[int, int, int, int]] = None,
                  slow_factor: float = 0.5) -> None:
    """追蹤單支影片並輸出中心座標檔

    Args:
        video_path: 影片路徑
        init_box  : (x, y, w, h)，若為 None 則手動框選
        slow_factor: 顯示播放慢速倍數 (預設 0.25× => 4)
    """
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"[WARN] Cannot open '{video_path}', skip.")
        return

    ok, frame = cap.read()
    if not ok:
        print(f"[WARN] Empty video '{video_path}', skip.")
        return

    # 讓使用者手動框選
    if init_box is None:
        init_box = cv2.selectROI(f"ROI → {video_path}", frame,
                                 showCrosshair=False, fromCenter=False)
        cv2.destroyWindow(f"ROI → {video_path}")

    if init_box == (0, 0, 0, 0):
        print(f"[WARN] ROI cancelled for '{video_path}', skip.")
        return

    # --- 建立 tracker ---
    tracker = cv2.TrackerCSRT_create()
    tracker.init(frame, init_box)

    # --- 建立輸出檔 ---
    stem     = os.path.splitext(os.path.basename(video_path))[0]
    out_name = f"traj_{stem}_marker.output"
    out_f    = open(out_name, "w", encoding="utf-8")
    out_f.write("#frame,cx,cy\n")

    # --- 顯示初始化框 (紫) ---
    x, y, w, h = map(int, init_box)
    init_disp   = frame.copy()
    cv2.rectangle(init_disp, (x, y), (x + w, y + h), (255, 0, 255), 2)
    cv2.imshow("Initial zone", init_disp)
    cv2.waitKey(500)
    cv2.destroyWindow("Initial zone")

    fps      = cap.get(cv2.CAP_PROP_FPS) or 30.0
    delay_ms = int(1000 / fps * 0.25)

    frame_id = 0
    while True:
        ok, frame = cap.read()
        if not ok:
            break

        ok_trk, box = tracker.update(frame)
        if ok_trk:
            x, y, w, h = map(int, box)
            cx, cy     = x + w // 2, y + h // 2
            out_f.write(f"{frame_id},{cx},{cy}\n")
            # 追蹤視覺化
            cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 0, 0), 2)
            cv2.circle(frame, (cx, cy), 4, (0, 255, 255), -1)

        cv2.imshow(f"Tracking → {stem}", frame)
        if cv2.waitKey(delay_ms) & 0xFF == 27:          # ESC 結束
            break
        frame_id += 1

    out_f.close()
    cap.release()
    cv2.destroyWindow(f"Tracking → {stem}")
    print(f"[OK] {video_path} → {out_name}")

# ------------------------------------------------------
# 入口點
# ------------------------------------------------------
def main() -> None:
    args = sys.argv[1:]

    if not args:
        # 無參數：批次模式
        print("[INFO] Batch mode: process a.mp4 … u.mp4")
        for vid, bbox in DEFAULT_JOBS:
            process_video(vid, bbox)
    else:
        # 單檔 / 手動模式
        video_path = args[0]
        box = tuple(map(int, args[1:5])) if len(args) >= 5 else None
        process_video(video_path, box)

if __name__ == "__main__":
    main()
