# chatbot_card.py
import os, pickle, json, re
import torch, numpy as np
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer, util
from openai import OpenAI

# ───────────────────────────────
# 1. 환경 변수 및 키 설정
# ───────────────────────────────
load_dotenv()
openai_api_key = os.getenv("OPENAI_API_KEY")
if not openai_api_key:
    raise ValueError("OPENAI_API_KEY가 .env에 설정되어 있지 않습니다.")
client = OpenAI(api_key=openai_api_key)

# ───────────────────────────────
# 2. 상수 · 모델 준비
# ───────────────────────────────
VECTOR_PATH = "data/card_vectors.pkl"
BASE_URL    = "http://localhost:8090/cards/detail?no="
device      = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = SentenceTransformer(
    "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
    device=device
)

# ───────────────────────────────
# 3. 전역 변수
# ───────────────────────────────
data, vectors, texts = None, None, None
session_histories: dict[str, list[dict]] = {}
session_meta      : dict[str, dict]      = {}

# ───────────────────────────────
# 4. 벡터 로딩
# ───────────────────────────────
def reload_vectors() -> None:
    global data, vectors, texts
    with open(VECTOR_PATH, "rb") as f:
        obj = pickle.load(f)
        data, vectors, texts = obj["data"], obj["vectors"], obj["texts"]
    print(f"[INFO] 카드 벡터 {len(data)}건 로딩")

reload_vectors()

# ───────────────────────────────
# 5. 유틸
# ───────────────────────────────
def build_block(idx:int) -> str:
    c = data[idx]
    link = f"{BASE_URL}{c['CARD_NO']}"
    return json.dumps({
        "카드명" : c["CARD_NAME"],
        "브랜드" : c["CARD_BRAND"],
        "혜택"   : f"{c['SERVICE']}, {c['S_SERVICE']}",
        "연회비" : f"{c['ANNUAL_FEE']}원",
        "링크"   : link
    }, ensure_ascii=False, indent=2)

def wants_link(text:str) -> bool:
    return bool(re.search(r"(링크.*(줘|주세요|줄래|필요)|\b네\b|좋아)", text, re.I))

def is_thanks(t:str)->bool:
    return bool(re.search(r"(고마|감사|수고|덕분|좋은\s*하루)", t, re.I))

def is_follow_up(t:str)->bool:
    kw = ["그 카드", "이 카드", "방금", "앞에서", "말한 카드",
          "추가 혜택", "다른 혜택", "더 알려", "상세 혜택", "더 있어"]
    return any(k in t for k in kw)

def normalize(answer:str)->str:
    answer = re.sub(r"\[.*?\]\((https?://[^\s)]+)\)", r"\1", answer)
    return re.sub(r"\n{3,}", "\n\n", answer).strip()

# ───────────────────────────────
# 6. 메인
# ───────────────────────────────
def chat_with_card_bot(msg:str, session_id:str="default") -> str:
    msg = msg.strip()

    # 세션·메타 초기
    if session_id not in session_histories:
        session_histories[session_id] = [
            {"role":"system","content":"당신은 고객 맞춤 카드 추천 AI입니다."}
        ]
        session_meta[session_id] = {
            "greeted":False,
            "focus_idx":None,      # 대표 카드 1장
            "await_link":False
        }
    meta = session_meta[session_id]

    # ───────── ① 링크만 요청?
    if meta["await_link"] and wants_link(msg):
        idx = meta["focus_idx"]
        link = f"{BASE_URL}{data[idx]['CARD_NO']}"
        name = data[idx]["CARD_NAME"]
        meta["await_link"] = False
        return f"{name} 신청 링크입니다:\n{link}"
    meta["await_link"] = False   # 어떤 경우든 일단 해제

    # ───────── ② 감사 인사?
    if is_thanks(msg):
        return "도움이 되었다니 기쁩니다! 또 궁금한 점 있으면 말씀해 주세요."

    # ───────── ③ 카드 키워드가 없는 일반 말
    if not re.search(r"카드|혜택|연회비|추천|할인|적립|캐시백", msg):
        if not meta["greeted"]:
            meta["greeted"]=True
            return "안녕하세요! 카드 관련 질문을 해주시면 추천을 도와드릴게요."
        return "카드 혜택이나 조건을 알려주시면 맞춤 추천을 드릴게요!"

    # ───────── ④ follow‑up?
    if meta["focus_idx"] is not None and is_follow_up(msg):
        focus_block = build_block(meta["focus_idx"])
        prompt_user = f"""
이 카드에 대해 더 설명해달라고 하셨습니다.

카드 정보:
{focus_block}

질문:
{msg}

규칙
- 2~4줄 말풍선 스타일로 추가 혜택이나 상세 정보를 설명
- 마지막 줄에 '신청 링크가 필요하시면 말씀해 주세요.' 문구 포함
""".strip()
        session_histories[session_id].append({"role":"user","content":prompt_user})
        answer = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=session_histories[session_id],
            temperature=0.4,max_tokens=300
        ).choices[0].message.content.strip()
        answer = normalize(answer)
        session_histories[session_id].append({"role":"assistant","content":answer})
        meta["await_link"]=True
        return answer

    # ───────── ⑤ 새 추천 산출
    qv = model.encode(msg, convert_to_tensor=True)
    sims = util.cos_sim(qv, torch.tensor(np.array(vectors),dtype=torch.float32))[0]
    focus_idx = int(torch.argmax(sims).item())
    meta["focus_idx"] = focus_idx

    card_block = build_block(focus_idx)
    prompt_user = f"""
아래 카드 정보를 참고해 고객에게 1장의 카드를 추천하고 이유를 설명하세요.

카드 정보:
{card_block}

규칙
- 2~4줄 말풍선 스타일로 카드명·주요 혜택·연회비를 설명
- 링크는 주지 마세요.
- 마지막 줄에 '신청 링크가 필요하시면 말씀해 주세요.' 문구 포함
    """.strip()

    session_histories[session_id].append({"role":"user","content":prompt_user})
    answer = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=session_histories[session_id],
        temperature=0.4,max_tokens=300
    ).choices[0].message.content.strip()
    answer = normalize(answer)
    session_histories[session_id].append({"role":"assistant","content":answer})

    meta["await_link"]=True
    meta["greeted"]=True
    return answer
