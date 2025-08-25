# main.py  (포트 8000, venv에서 실행)
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

from feedback_analyze import router as feedback_router

import os, time, logging
import pandas as pd
from typing import List, Optional
from logging.handlers import RotatingFileHandler

# ───────────────────────────────
# 로깅 설정
# ───────────────────────────────
LOG_DIR = "logs"
os.makedirs(LOG_DIR, exist_ok=True)

logger = logging.getLogger("bnk-main")
logger.setLevel(logging.INFO)

fmt = logging.Formatter("%(asctime)s %(levelname)s %(message)s")

file_handler = RotatingFileHandler(
    os.path.join(LOG_DIR, "main.log"),
    maxBytes=1_000_000,
    backupCount=5,
    encoding="utf-8",
)
file_handler.setFormatter(fmt)

console_handler = logging.StreamHandler()
console_handler.setFormatter(fmt)

if not logger.handlers:
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

# ───────────────────────────────
# .env 로드
# ───────────────────────────────
load_dotenv()

# ───────────────────────────────
# FastAPI 앱
# ───────────────────────────────
app = FastAPI(title="BNK Main API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 배포 시 도메인 제한 권장
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ───────────────────────────────
# FAQ/챗봇 관련 (기존 유지)
# ───────────────────────────────
class Faq(BaseModel):
    faqNo: int
    faqQuestion: str
    faqAnswer: str
    regDate: Optional[str] = None
    writer: Optional[str] = None
    admin: Optional[str] = None
    cattegory: Optional[str] = None

@app.post("/update-faq")
async def update_faq(faqs: List[Faq]):
    df = pd.DataFrame([faq.dict() for faq in faqs])
    df_save = df[["faqQuestion", "faqAnswer"]]
    df_save.columns = ["input_text", "target_text"]
    df_save.to_csv("bank_chatbot_data.csv", index=False, encoding="utf-8-sig")
    return {"message": "FAQ 업데이트 완료"}

class AskRequest(BaseModel):
    question: str

# 주의: 아래 3개 import는 기존 환경에 맞춰 두세요.
from chatbot_module import chat_with_bot, reload_vectors
from train_card_from_db import run_full_card_training, get_last_training_time
from chatbot_card import chat_with_card_bot

@app.post("/ask")
async def ask(query: AskRequest):
    answer = chat_with_bot(query.question)
    return {"answer": answer}

@app.post("/reload-model")
async def reload_model():
    reload_vectors()
    return {"message": "FAQ 모델 리로드 완료"}

@app.post("/train-card")
async def train_card():
    try:
        run_full_card_training()
        return {"message": "카드 정보 학습 완료"}
    except Exception as e:
        return {"error": str(e)}

@app.get("/train-card/time")
async def train_time():
    return {"last_trained": get_last_training_time()}

class CardChatRequest(BaseModel):
    question: str

@app.post("/card-chat")
def card_chat(req: CardChatRequest):
    return {"answer": chat_with_card_bot(req.question)}

# ───────────────────────────────
# 본인인증 (기존 유지)
# ───────────────────────────────
from verification.verify_service import verify_identity

@app.post("/verify")
async def verify_endpoint(
    id_image: UploadFile = File(...),
    face_image: UploadFile = File(...),
    expected_rrn: str = Form(...),
    face_threshold: float = Form(default=0.65),
):
    id_bytes = await id_image.read()
    face_bytes = await face_image.read()
    try:
        result = verify_identity(
            id_bytes=id_bytes,
            face_bytes=face_bytes,
            expected_rrn=expected_rrn,
            face_threshold=face_threshold,
        )
        return result
    except Exception as e:
        logger.exception("verify_error")
        return {"status": "ERROR", "reason": str(e)}

@app.post("/ocr-id")
async def ocr_id(idImage: UploadFile = File(...)):
    from verification.id_service import extract_rrn
    try:
        id_bytes = await idImage.read()
        ocr = extract_rrn(id_bytes)  # {'front','gender','tail','masked','preview'}
        return {"status": "OK", "ocr": ocr}
    except Exception as e:
        logger.exception("ocr_error")
        return {"status": "ERROR", "reason": str(e)}

# 피드백/분석 등 기존 라우터 유지
app.include_router(feedback_router)

# ───────────────────────────────
# 헬스체크/버전
# ───────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "service": "main"}

@app.get("/version")
def version():
    return {"version": os.getenv("APP_VERSION", "1.0.0")}

# ───────────────────────────────
# (선택) YOLO Moderation 프록시
#   - YOLO 전용 서버(venv_cuda, 8001)가 있을 때,
#     8000 → 8001로 중계하고 싶다면 주석 해제해서 사용
# ───────────────────────────────
"""
import httpx

@app.post("/moderate")
async def moderate_proxy(
    image: UploadFile | None = File(default=None),
    imageUrl: str | None = Form(default=None),
    customNo: int | None = Form(default=None),
    memberNo: int | None = Form(default=None),
):
    # YOLO 서비스 주소
    yolo_url = os.getenv("YOLO_SERVICE_URL", "http://127.0.0.1:8001/moderate")
    data = {"imageUrl": imageUrl, "customNo": customNo, "memberNo": memberNo}
    files = None
    if image is not None:
        raw = await image.read()
        files = {"image": ("card.png", raw, "image/png")}
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.post(yolo_url, data=data, files=files)
            r.raise_for_status()
            return r.json()
    except httpx.HTTPError as e:
        logger.exception("moderate_proxy_error")
        raise HTTPException(status_code=502, detail="moderation_service_unavailable")
"""
