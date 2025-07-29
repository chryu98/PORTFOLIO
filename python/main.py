# main.py

from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# 챗봇 관련 함수 import
from chatbot_module import chat_with_bot, reload_vectors  # FAQ 기반 챗봇
from train_card_from_db import run_full_card_training, get_last_training_time  # 카드 학습
from chatbot_card import chat_with_card_bot  # 카드 추천 챗봇

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
    allow_origins=["*"],  # 배포 시 도메인 제한 필요
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ───────────────────────────────
# 1. FAQ 모델 정의
# ───────────────────────────────
class Faq(BaseModel):
    faqNo: int
    faqQuestion: str
    faqAnswer: str
    regDate: Optional[str] = None
    writer: Optional[str] = None
    admin: Optional[str] = None
    cattegory: Optional[str] = None

# ───────────────────────────────
# 2. FAQ → CSV 저장 (학습용)
# ───────────────────────────────
@app.post("/update-faq")
async def update_faq(faqs: List[Faq]):
    df = pd.DataFrame([faq.dict() for faq in faqs])
    df_save = df[["faqQuestion", "faqAnswer"]]
    df_save.columns = ["input_text", "target_text"]
    df_save.to_csv("bank_chatbot_data.csv", index=False, encoding="utf-8-sig")
    return {"message": "FAQ 업데이트 완료"}

# ───────────────────────────────
# 3. FAQ 챗봇 질문 응답
# ───────────────────────────────
class AskRequest(BaseModel):
    question: str

@app.post("/ask")
async def ask(query: AskRequest):
    answer = chat_with_bot(query.question)
    return {"answer": answer}

# ───────────────────────────────
# 4. 모델 리로드 (FAQ용 벡터 다시 불러오기)
# ───────────────────────────────
@app.post("/reload-model")
async def reload_model():
    reload_vectors()
    return {"message": "FAQ 모델 리로드 완료"}

# ───────────────────────────────
# 5. 카드 챗봇 → 학습 트리거
# ───────────────────────────────
@app.post("/train-card")
async def train_card():
    try:
        run_full_card_training()
        return {"message": "카드 정보 학습 완료"}
    except Exception as e:
        return {"error": str(e)}

# ───────────────────────────────
# 6. 카드 챗봇 → 마지막 학습 시간 조회
# ───────────────────────────────
@app.get("/train-card/time")
async def train_time():
    return {"last_trained": get_last_training_time()}

# ───────────────────────────────
# 7. 카드 챗봇 → 질문 응답
# ───────────────────────────────
# Pydantic 요청 모델
class CardChatRequest(BaseModel):
    question: str

@app.post("/card-chat")
def card_chat(req: CardChatRequest):
    return {"answer": chat_with_card_bot(req.question)}


