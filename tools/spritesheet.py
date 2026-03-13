#!/usr/bin/env python3
"""
spritesheet.py — 스프라이트시트 생성 + 슬라이싱 통합 도구
pack: 개별 프레임 → 스프라이트시트
slice: 스프라이트시트 → 개별 프레임
"""

import argparse
import glob
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow required. Install: pip install Pillow", file=sys.stderr)
    sys.exit(1)


def pack_frames(frames_pattern: str, cols: int, output: str):
    """개별 프레임을 스프라이트시트로 합침"""
    frame_paths = sorted(glob.glob(frames_pattern))
    if not frame_paths:
        print(f"ERROR: No frames found matching: {frames_pattern}", file=sys.stderr)
        sys.exit(1)

    frames = [Image.open(p).convert("RGBA") for p in frame_paths]
    w, h = frames[0].size
    rows = (len(frames) + cols - 1) // cols

    sheet = Image.new("RGBA", (w * cols, h * rows), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        x = (i % cols) * w
        y = (i // cols) * h
        sheet.paste(frame, (x, y))

    os.makedirs(os.path.dirname(output) or ".", exist_ok=True)
    sheet.save(output)
    print(f"OK: Packed {len(frames)} frames → {output} ({sheet.size[0]}x{sheet.size[1]})")


def slice_sheet(input_path: str, cols: int, rows: int, output_dir: str):
    """스프라이트시트를 개별 프레임으로 슬라이싱"""
    sheet = Image.open(input_path).convert("RGBA")
    frame_w = sheet.width // cols
    frame_h = sheet.height // rows

    os.makedirs(output_dir, exist_ok=True)

    count = 0
    for row in range(rows):
        for col in range(cols):
            x = col * frame_w
            y = row * frame_h
            frame = sheet.crop((x, y, x + frame_w, y + frame_h))

            # 완전 투명한 프레임은 건너뛰기
            if frame.getextrema()[3][1] == 0:  # alpha 채널 최대값이 0
                continue

            frame_path = os.path.join(output_dir, f"frame_{count:04d}.png")
            frame.save(frame_path)
            count += 1

    print(f"OK: Sliced {count} frames → {output_dir}/ (each {frame_w}x{frame_h})")


def main():
    parser = argparse.ArgumentParser(description="Spritesheet pack/slice tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # pack
    pack_parser = subparsers.add_parser("pack", help="Pack frames into spritesheet")
    pack_parser.add_argument("--frames", required=True,
                             help="Frame files glob pattern")
    pack_parser.add_argument("--cols", type=int, required=True,
                             help="Number of columns")
    pack_parser.add_argument("--output", required=True,
                             help="Output spritesheet path")

    # slice
    slice_parser = subparsers.add_parser("slice", help="Slice spritesheet into frames")
    slice_parser.add_argument("--input", required=True,
                              help="Input spritesheet path")
    slice_parser.add_argument("--cols", type=int, required=True,
                              help="Number of columns")
    slice_parser.add_argument("--rows", type=int, required=True,
                              help="Number of rows")
    slice_parser.add_argument("--output-dir", required=True,
                              help="Output directory for frames")

    args = parser.parse_args()

    if args.command == "pack":
        pack_frames(args.frames, args.cols, args.output)
    elif args.command == "slice":
        slice_sheet(args.input, args.cols, args.rows, args.output_dir)


if __name__ == "__main__":
    main()
