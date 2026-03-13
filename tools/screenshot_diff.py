#!/usr/bin/env python3
"""
screenshot_diff.py — SSIM 기반 스크린샷 비교
reference.png 대비 게임 스크린샷의 구조적 유사도를 측정합니다.
"""

import argparse
import json
import sys

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("ERROR: Pillow and numpy required. Install: pip install Pillow numpy",
          file=sys.stderr)
    sys.exit(1)


def compute_ssim(img1: np.ndarray, img2: np.ndarray) -> float:
    """
    간단한 SSIM 구현 (scikit-image 없이).
    https://en.wikipedia.org/wiki/Structural_similarity
    """
    C1 = (0.01 * 255) ** 2
    C2 = (0.03 * 255) ** 2

    img1 = img1.astype(np.float64)
    img2 = img2.astype(np.float64)

    mu1 = img1.mean()
    mu2 = img2.mean()
    sigma1_sq = img1.var()
    sigma2_sq = img2.var()
    sigma12 = ((img1 - mu1) * (img2 - mu2)).mean()

    ssim = ((2 * mu1 * mu2 + C1) * (2 * sigma12 + C2)) / \
           ((mu1 ** 2 + mu2 ** 2 + C1) * (sigma1_sq + sigma2_sq + C2))

    return float(ssim)


def compare_images(reference_path: str, screenshot_path: str) -> dict:
    ref = Image.open(reference_path).convert("RGB")
    ss = Image.open(screenshot_path).convert("RGB")

    # 같은 크기로 리사이즈
    target_size = (min(ref.width, ss.width), min(ref.height, ss.height))
    ref = ref.resize(target_size, Image.LANCZOS)
    ss = ss.resize(target_size, Image.LANCZOS)

    ref_arr = np.array(ref)
    ss_arr = np.array(ss)

    # 채널별 SSIM 계산 후 평균
    ssim_r = compute_ssim(ref_arr[:, :, 0], ss_arr[:, :, 0])
    ssim_g = compute_ssim(ref_arr[:, :, 1], ss_arr[:, :, 1])
    ssim_b = compute_ssim(ref_arr[:, :, 2], ss_arr[:, :, 2])
    ssim = (ssim_r + ssim_g + ssim_b) / 3.0

    # 판정
    if ssim >= 0.85:
        verdict = "good"
    elif ssim >= 0.7:
        verdict = "acceptable"
    else:
        verdict = "fail"

    return {
        "ssim": round(ssim, 4),
        "ssim_r": round(ssim_r, 4),
        "ssim_g": round(ssim_g, 4),
        "ssim_b": round(ssim_b, 4),
        "verdict": verdict,
        "reference": reference_path,
        "screenshot": screenshot_path,
        "size": f"{target_size[0]}x{target_size[1]}"
    }


def main():
    parser = argparse.ArgumentParser(description="SSIM screenshot comparison")
    parser.add_argument("--reference", required=True, help="Reference image")
    parser.add_argument("--screenshot", required=True, help="Screenshot to compare")

    args = parser.parse_args()
    result = compare_images(args.reference, args.screenshot)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
