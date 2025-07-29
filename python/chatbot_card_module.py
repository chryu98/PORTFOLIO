# chatbot_card_module.py

import os
import json
import torch
from sentence_transformers import SentenceTransformer, util

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 모델 로딩
MODEL_ID = "snunlp/KR-SBERT-V40K-klueNLI-augSTS"
embedder = SentenceTransformer(MODEL_ID).to(device)

# 카드 벡터 및 메타데이터 로드
VEC_PATH = "data/card_vectors.pkl"
META_PATH = "data/card_meta.json"

card_data = {
    "vectors": None,
    "texts": [],
    "data": []
}

if os.path.exists(VEC_PATH) and os.path.exists(META_PATH):
    card_data["vectors"] = torch.load(VEC_PATH, map_location=device)
    with open(META_PATH, encoding="utf-8") as f:
        meta = json.load(f)
        card_data["texts"] = meta["input_texts"]
        card_data["data"] = meta["card_data"]
    print(f"→ 카드 벡터 로딩 완료! 총 {len(card_data['texts'])}개")

else:
    print("⚠️ 카드 임베딩 파일이 없습니다.")

# 챗봇 응답 함수
def chat_with_card_bot(user_text):
    if not card_data["vectors"]:
        return {"error": "카드 벡터 데이터가 없습니다."}

    user_vec = embedder.encode(user_text, convert_to_tensor=True)
    scores = util.cos_sim(user_vec, card_data["vectors"])[0]

    top_idx = torch.argmax(scores).item()
    top_score = scores[top_idx].item()

    if top_score < 0.5:
        return {"error": "죄송합니다. 관련된 카드를 찾지 못했어요."}

    result = {
        "matched_card": card_data["data"][top_idx],
        "matched_text": card_data["texts"][top_idx],
        "similarity": round(top_score, 4)
    }

    return result
