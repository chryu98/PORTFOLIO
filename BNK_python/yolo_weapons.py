# yolo_weapons.py
import os, io
from typing import Optional, Tuple
from PIL import Image
from ultralytics import YOLO
import requests

# === 설정 ===
# 환경변수로 덮어쓰기 가능: WEAPON_MODEL_PATH
MODEL_PATH = os.getenv(
    "WEAPON_MODEL_PATH",
    r"C:\java_class\CP\bnkcard\BNK_python\data\weights\weapons_gpu_memsafe5\weights\best.pt"
)
WEAPON_THRESHOLD = float(os.getenv("WEAPON_THRESHOLD", "0.60"))
WEAPON_CLASSES = {0: "knife", 1: "gun"}

# 전역 모델 핸들 (지연 로드)
_model: Optional[YOLO] = None

def _lazy_load():
    """모델을 최초 1회만 로드"""
    global _model
    if _model is None:
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(
                f"YOLO model file not found: {MODEL_PATH}\n"
                "환경변수 WEAPON_MODEL_PATH로 경로를 지정하거나, 파일 위치를 확인하세요."
            )
        _model = YOLO(MODEL_PATH)

def _load_pil_from_bytes(raw: bytes) -> Image.Image:
    return Image.open(io.BytesIO(raw)).convert("RGB")

def _load_pil_from_url(url: str) -> Image.Image:
    r = requests.get(url, timeout=10)
    r.raise_for_status()
    return _load_pil_from_bytes(r.content)

def detect_weapons_pil(pil_img: Image.Image) -> Tuple[Optional[str], float]:
    _lazy_load()
    # 낮은 conf로 모두 탐지 → 최종 필터는 우리가 WEAPON_THRESHOLD로
    res = _model(pil_img, imgsz=640, conf=0.001, verbose=False)[0]
    best_label, best_conf = None, 0.0
    for b in res.boxes:
        cls_idx = int(b.cls.item())
        conf = float(b.conf.item())
        label = WEAPON_CLASSES.get(cls_idx, str(cls_idx))
        if conf > best_conf:
            best_conf = conf
            best_label = label
    return best_label, best_conf

def infer_from_bytes(raw: bytes) -> Tuple[str, str, Optional[str], Optional[float]]:
    pil = _load_pil_from_bytes(raw)
    label, conf = detect_weapons_pil(pil)
    if label and conf >= WEAPON_THRESHOLD:
        reason = f"VIOLENCE_{label.upper()}"
        return "REJECT", reason, label, conf
    return "ACCEPT", "OK", None, None

def infer_from_url(url: str) -> Tuple[str, str, Optional[str], Optional[float]]:
    pil = _load_pil_from_url(url)
    label, conf = detect_weapons_pil(pil)
    if label and conf >= WEAPON_THRESHOLD:
        reason = f"VIOLENCE_{label.upper()}"
        return "REJECT", reason, label, conf
    return "ACCEPT", "OK", None, None
