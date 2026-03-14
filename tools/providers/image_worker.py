"""Cloudflare Worker 이미지 프록시 Provider"""

import os
import json
import urllib.request
import urllib.error
from . import ImageProvider


class WorkerImageProvider(ImageProvider):

    def __init__(self):
        self.api_key = os.environ.get("WORKER_IMAGE_API_KEY")
        if not self.api_key:
            raise ValueError("WORKER_IMAGE_API_KEY environment variable required")
        self.url = "https://worker-image-proxy.acappella-vp.workers.dev/generate"

    def generate(self, prompt: str, size: str = "1024x1024",
                 aspect: str = "1:1") -> bytes:
        parts = size.split("x") if "x" in size else []
        w, h = (int(parts[0]), int(parts[1])) if len(parts) >= 2 else (1024, 1024)

        payload = {
            "prompt": prompt,
            "width": w,
            "height": h,
            "num_steps": 4,
        }

        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            self.url,
            data=data,
            headers={
                "X-API-key": self.api_key,
                "Content-Type": "application/json",
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            raise RuntimeError(
                f"Worker API error {e.code}: {e.read().decode('utf-8', errors='replace')[:200]}"
            ) from e

    @property
    def cost_per_image(self) -> float:
        return 0.002
