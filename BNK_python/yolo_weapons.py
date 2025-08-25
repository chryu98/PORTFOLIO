# yolo_weapons.py
import os, io
from typing import Optional, Tuple
from PIL import Image
from ultralytics import YOLO
import requests

MODEL_PATH = os.getenv("WEAPON_MODEL_PATH", "data/weights/weapons_v1/best.pt")
WEAPON_THRESHOLD = float(os.getenv("WEAPON_THRESHOLD", "0.60"))
WEAPON_CLASSES = {0: "knife", 1: "gun"}

_model: Optional[YOLO] = None

def _lazy_load():
    global _model
    if _model is None:
        _model = YOLO(MODEL_PATH)

def _load_pil_from_bytes(raw: bytes) -> Image.Image:
    return Image.open(io.BytesIO(raw)).convert("RGB")

def _load_pil_from_url(url: str) -> Image.Image:
    r = requests.get(url, timeout=10)
    r.raise_for_status()
    return _load_pil_from_bytes(r.content)

def detect_weapons_pil(pil_img: Image.Image) -> Tuple[Optional[str], float]:
    _lazy_load()
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
