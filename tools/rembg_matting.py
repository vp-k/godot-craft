#!/usr/bin/env python3
"""
rembg_matting.py — 배경 제거 + 알파 매팅
스프라이트 이미지에서 배경을 제거하여 투명 PNG로 변환합니다.
"""

import argparse
import sys

try:
    from rembg import remove
    from PIL import Image
except ImportError:
    print("ERROR: rembg and Pillow required. Install: pip install rembg Pillow",
          file=sys.stderr)
    sys.exit(1)


def remove_background(input_path: str, output_path: str,
                      alpha_matting: bool = True):
    """배경 제거"""
    with open(input_path, "rb") as f:
        input_data = f.read()

    output_data = remove(
        input_data,
        alpha_matting=alpha_matting,
        alpha_matting_foreground_threshold=240,
        alpha_matting_background_threshold=10,
        alpha_matting_erode_size=10,
    )

    with open(output_path, "wb") as f:
        f.write(output_data)

    # 결과 확인
    img = Image.open(output_path)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
        img.save(output_path)

    print(f"OK: Background removed → {output_path} ({img.size[0]}x{img.size[1]}, RGBA)")


def main():
    parser = argparse.ArgumentParser(description="Remove background from sprite images")
    parser.add_argument("--input", required=True, help="Input image path")
    parser.add_argument("--output", required=True, help="Output image path (PNG)")
    parser.add_argument("--no-matting", action="store_true",
                        help="Disable alpha matting (faster but rougher edges)")

    args = parser.parse_args()
    remove_background(args.input, args.output, not args.no_matting)


if __name__ == "__main__":
    main()
