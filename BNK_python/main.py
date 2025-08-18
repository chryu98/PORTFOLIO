from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
import shutil
from dotenv import load_dotenv

# 챗봇 관련 import
from chatbot_module import chat_with_bot, reload_vectors
from train_card_from_db import run_full_card_training, get_last_training_time
from chatbot_card import chat_with_card_bot

# 본인인증 import
from verification.verify_service import verify_identity

# ───────────────────────────────
# 환경 변수 로드
# ───────────────────────────────
load_dotenv()

# ───────────────────────────────
# FastAPI 앱 생성 및 CORS 설정
# ───────────────────────────────
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 배포 시 도메인 제한 권장
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ───────────────────────────────
# FAQ 모델 정의
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
# 본인인증 API (주민번호 + 얼굴)
# ───────────────────────────────
@app.post("/verify")
async def verify(
    id_image: UploadFile = File(...),
    face_image: UploadFile = File(...),
    expected_rrn: str = Form(...)
):
    # 업로드 파일 저장
    id_path = f"data/{id_image.filename}"
    face_path = f"data/{face_image.filename}"

    with open(id_path, "wb") as f:
        shutil.copyfileobj(id_image.file, f)
    with open(face_path, "wb") as f:
        shutil.copyfileobj(face_image.file, f)

    # 본인인증 실행
    return verify_identity(id_path, face_path, expected_rrn)
