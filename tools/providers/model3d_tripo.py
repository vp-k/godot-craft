"""Tripo3D 이미지→GLB Provider (기본)"""

import os
import json
import time
import urllib.request
import urllib.error
import base64
from pathlib import Path
from . import Model3DProvider


class TripoModel3DProvider(Model3DProvider):

    def __init__(self):
        self.api_key = os.environ.get("TRIPO_API_KEY")
        if not self.api_key:
            raise ValueError("TRIPO_API_KEY environment variable required")
        self.base_url = "https://api.tripo3d.ai/v2/openapi"

    def image_to_glb(self, image: Path, quality: str = "medium") -> bytes:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        # 이미지를 base64로 인코딩
        with open(image, "rb") as f:
            img_b64 = base64.b64encode(f.read()).decode("utf-8")

        # 태스크 생성
        payload = {
            "type": "image_to_model",
            "file": {
                "type": "png",
                "data": img_b64
            }
        }

        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            f"{self.base_url}/task",
            data=data,
            headers=headers,
            method="POST"
        )

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                result = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            raise RuntimeError(f"Tripo API error {e.code}: {e.read().decode('utf-8', errors='replace')[:200]}") from e

        task_id = result.get("data", {}).get("task_id")
        if not task_id:
            raise RuntimeError(f"No task_id in Tripo response: {result}")

        # 폴링
        for _ in range(120):
            req = urllib.request.Request(
                f"{self.base_url}/task/{task_id}",
                headers=headers
            )
            try:
                with urllib.request.urlopen(req, timeout=30) as resp:
                    status = json.loads(resp.read().decode("utf-8"))
            except urllib.error.HTTPError as e:
                if e.code == 429 or e.code >= 500:
                    time.sleep(3)
                    continue
                raise RuntimeError(f"Tripo API error {e.code}: {e.read().decode('utf-8', errors='replace')[:200]}") from e
            except urllib.error.URLError:
                time.sleep(3)
                continue

            state = status.get("data", {}).get("status")
            if state == "success":
                model_url = status.get("data", {}).get("output", {}).get("model")
                if not model_url:
                    raise RuntimeError(f"No model URL in Tripo response: {status}")
                with urllib.request.urlopen(model_url, timeout=60) as resp:
                    return resp.read()
            elif state == "failed":
                raise RuntimeError(f"Tripo task failed: {status.get('data', {}).get('message', 'unknown')}")

            time.sleep(3)

        raise TimeoutError("Tripo3D generation timed out")

    @property
    def cost_per_model(self) -> float:
        return 0.15
