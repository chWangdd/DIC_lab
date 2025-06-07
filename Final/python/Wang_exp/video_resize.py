#!/usr/bin/env python
"""
resize_rotate.py  –  batch-process videos: rotate then resize every frame.

Usage examples
--------------
# 1) Batch mode, default rotates 90° on files a.MOV–u.MOV and resizes to 1080×1080:
python video_resize.py

# 2) Single file mode, explicit src and dst plus optional flags:
python video_resize.py input.mov output.mp4 --rotate 270 --size 1280 720
"""
import cv2
import argparse
import pathlib
import sys

# ──────────────────────── core processing ───────────────────────────────────
def process(src_path: pathlib.Path, dst_path: pathlib.Path,
            target_w: int, target_h: int, rot: int):
    cap = cv2.VideoCapture(str(src_path))
    if not cap.isOpened():
        print(f"[ERROR] cannot open '{src_path}'")
        return
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    fourc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(dst_path), fourc, fps, (target_w, target_h))

    rot_code_map = {0: None,
                    90: cv2.ROTATE_90_CLOCKWISE,
                   180: cv2.ROTATE_180,
                   270: cv2.ROTATE_90_COUNTERCLOCKWISE}
    rot_code = rot_code_map.get(rot)

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        if rot_code is not None:
            frame = cv2.rotate(frame, rot_code)
        frame = cv2.resize(frame, (target_w, target_h), interpolation=cv2.INTER_AREA)
        writer.write(frame)

    cap.release()
    writer.release()
    print(f"✓ finished → {dst_path}")

# ─────────────────────────── entrypoint ─────────────────────────────────────
def main():
    # Batch mode if no args provided
    if len(sys.argv) == 1:
        letters = [chr(c) for c in range(ord('a'), ord('u') + 1)]
        # defaults match original parser defaults
        target_w, target_h = 1080, 1080
        rot = 90
        for letter in letters:
            src = pathlib.Path(f"{letter}.MOV")
            dst = pathlib.Path(f"{letter}.mp4")
            print(f"Processing {src} → {dst}")
            process(src, dst, target_w, target_h, rot)
    else:
        parser = argparse.ArgumentParser(
            description="Rotate and resize a single video file.")
        parser.add_argument("src", help="input video file")
        parser.add_argument("dst", help="output video file (ext infers container)")
        parser.add_argument("--size", type=int, nargs=2, metavar=("W", "H"),
                            default=[1080, 1080],
                            help="target width height (default 1080 1080)")
        parser.add_argument("--rotate", type=int,
                            choices=[0, 90, 180, 270], default=0,
                            help="clockwise rotation before resize (degrees)")
        args = parser.parse_args()
        process(pathlib.Path(args.src), pathlib.Path(args.dst),
                args.size[0], args.size[1], args.rotate)

if __name__ == '__main__':
    main()
