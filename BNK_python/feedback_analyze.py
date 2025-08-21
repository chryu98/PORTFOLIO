# feedback_analyze.py
import os, json, logging
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger("verify")  # main.py에서 쓰는 동일 로거 사용

# ───────────────────────────────
# OpenAI 키가 있으면 우선 사용(없으면 규칙기반 폴백)
# ───────────────────────────────
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
_use_openai = False
_openai_client = None
if OPENAI_API_KEY:
    try:
        from openai import OpenAI
        _openai_client = OpenAI(api_key=OPENAI_API_KEY)
        _use_openai = True
        logger.info("OPENAI_API_KEY detected. Using OpenAI for feedback analysis.")
    except Exception as e:
        logger.warning("OpenAI init failed. Fallback to rule-based. %s", e)
        _use_openai = False

# ───────────────────────────────
# 라우터 & 스키마
# ───────────────────────────────
router = APIRouter()

class AnalyzeReq(BaseModel):
    feedback_no: int
    text: Optional[str] = None
    rating: Optional[int] = None

class AnalyzeResp(BaseModel):
    label: str
    score: float
    keywords: List[str]
    inconsistency: bool
    reason: Optional[str] = None
    analyzed_at: str

# 규칙 기반 백업
_POS = ["좋", "만족", "최고", "혜택", "디자인", "편리", "추천", "친절", "빠르", "유용"]
_NEG = ["별로", "불만", "최악", "느림", "수수료", "해지", "복잡", "불친절", "오류", "불편"]

def _rule_based(text: str, rating: Optional[int]) -> AnalyzeResp:
    t = (text or "").lower()
    pos = sum(w in t for w in _POS)
    neg = sum(w in t for w in _NEG)
    label = "POSITIVE" if pos >= neg else "NEGATIVE"
    score = round((pos - neg) / max(1, (pos + neg)) if (pos + neg) else 0.0, 4)

    kws = []
    for w in (_POS + _NEG):
        if w in t and w not in kws:
            kws.append(w)
    kws = kws[:10]

    inconsistency = False
    reason = None
    if rating is not None:
        if rating <= 2 and label == "POSITIVE":
            inconsistency, reason = True, "낮은 평점인데 긍정 표현"
        elif rating >= 4 and label == "NEGATIVE":
            inconsistency, reason = True, "높은 평점인데 부정 표현"

    return AnalyzeResp(
        label=label,
        score=float(score),
        keywords=kws,
        inconsistency=inconsistency,
        reason=reason,
        analyzed_at=datetime.now().isoformat()
    )

def _openai_analyze(text: str, rating: Optional[int]) -> AnalyzeResp:
    prompt = f"""
    너는 한국어 고객 피드백 분석기다.
    입력 문장에 대해 sentiment(label: POSITIVE/NEGATIVE), 
    score(-1.0~1.0, 소수 4자리), 
    keywords(최대 10개, 짧은 토큰 리스트), 
    inconsistency(평점과 감정 불일치 여부), reason(있으면 한 문장)을
    JSON으로만 출력해라.
    문장: {text!r}
    평점: {rating!r}
    """
    try:
        chat = _openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.0,
        )
        content = chat.choices[0].message.content
        data = json.loads(content)

        label = str(data.get("label", "POSITIVE")).upper()
        if label not in ("POSITIVE", "NEGATIVE"):
            label = "POSITIVE" if "POS" in label else "NEGATIVE"

        score = float(data.get("score", 0.0))
        keywords = data.get("keywords", [])
        if not isinstance(keywords, list):
            keywords = []
        inconsistency = bool(data.get("inconsistency", False))
        reason = data.get("reason")
        return AnalyzeResp(
            label=label,
            score=round(score, 4),
            keywords=keywords[:10],
            inconsistency=inconsistency,
            reason=reason,
            analyzed_at=datetime.now().isoformat()
        )
    except Exception as e:
        logger.warning("OpenAI analyze failed → fallback to rule-based: %s", e)
        return _rule_based(text, rating)

@router.get("/health")
def feedback_health():
    return {"status": "OK", "use_openai": _use_openai, "time": datetime.now().isoformat()}

@router.post("/analyze", response_model=AnalyzeResp)
async def analyze(req: AnalyzeReq):
    logger.info("feedback.analyze: feedback_no=%s rating=%s text_len=%s",
                req.feedback_no, req.rating, len(req.text or ""))
    return _openai_analyze(req.text or "", req.rating) if _use_openai else _rule_based(req.text or "", req.rating)
