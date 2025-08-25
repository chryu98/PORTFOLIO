# moderate_service.py (상단 순서 중요!!)
import os, time, logging
from dotenv import load_dotenv
load_dotenv()  # <= 먼저 호출

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from yolo_weapons import infer_from_bytes, infer_from_url, MODEL_PATH


load_dotenv()  # WEAPON_MODEL_PATH, WEAPON_THRESHOLD, MODEL_VER

# ── logger ───────────────────────────────────────────────────────────
logger = logging.getLogger("moderation")
if not logger.handlers:
    logger.setLevel(logging.INFO)
    h = logging.StreamHandler()
    h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
    logger.addHandler(h)
logger.info(f"[moderation] using model: {MODEL_PATH}")

# ── app ──────────────────────────────────────────────────────────────
app = FastAPI(title="moderation-service")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

class ModerateRes(BaseModel):
    decision: str                   # ACCEPT | REJECT
    reason: str                     # OK | VIOLENCE_KNIFE | VIOLENCE_GUN ...
    label: str | None = None
    confidence: float | None = None
    model: str = os.getenv("MODEL_VER", "yolo+weapons@v1")
    inferenceMs: int | None = None

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/model-info")
def model_info():
    return {"model_path": MODEL_PATH, "model_ver": os.getenv("MODEL_VER")}

@app.post("/moderate", response_model=ModerateRes)
async def moderate(
    image: UploadFile | None = File(default=None),
    imageUrl: str | None = Form(default=None),
    customNo: int | None = Form(default=None),
    memberNo: int | None = Form(default=None),
):
    if image is None and not imageUrl:
        raise HTTPException(status_code=400, detail="image or imageUrl required")

    t0 = time.time()
    try:
        if image is not None:
            raw = await image.read()
            decision, reason, label, conf = infer_from_bytes(raw)
        else:
            decision, reason, label, conf = infer_from_url(imageUrl)
    except Exception as e:
        logger.exception("moderation_error")
        # 디버깅 편하게 에러 메시지 그대로 반환
        raise HTTPException(status_code=500, detail=str(e))

    ms = int((time.time() - t0) * 1000)
    logger.info({"event":"moderate","decision":decision,"reason":reason,"label":label,"conf":conf,"t_ms":ms,
                 "customNo":customNo,"memberNo":memberNo})
    return ModerateRes(decision=decision, reason=reason, label=label, confidence=conf, inferenceMs=ms)
