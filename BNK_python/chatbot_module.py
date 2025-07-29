# chatbot_module.py

import os
import json
import torch
from sentence_transformers import SentenceTransformer, util
import pandas as pd
import glob

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"현재 디바이스: {device}")

# ------------------------------------------
# 1. CSV 로드 or my_txts 로 초기 학습
# ------------------------------------------

pairs = []
questions = []
answers = []
bank_mtime = 0

# (1) txt → pairs
all_files = glob.glob("./my_txts/*.txt")

if all_files:
    for filepath in all_files:
        with open(filepath, encoding="utf-8") as f:
            q = None
            for line in f:
                line = line.strip()
                if not line:
                    continue
                if line.startswith("Q:"):
                    q = line[2:].strip()
                elif line.startswith("A:"):
                    a = line[2:].strip()
                    if q and a:
                        pairs.append((q, a))
                        q = None

    # csv 저장
    try:
        df = pd.DataFrame(pairs, columns=["input_text", "target_text"])
        df.to_csv("bank_chatbot_data.csv", index=False, encoding="utf-8-sig")
        print("CSV 저장 완료!")
    except PermissionError:
        print("CSV 저장 실패! 혹시 파일 열려있나요?")

    questions = [q for q, _ in pairs]
    answers = [a for _, a in pairs]
    bank_mtime = max(os.path.getmtime(f) for f in all_files)

else:
    # (2) csv 로드
    if os.path.exists("bank_chatbot_data.csv"):
        df = pd.read_csv("bank_chatbot_data.csv")
        pairs = list(zip(df["input_text"], df["target_text"]))
        questions = [q for q, _ in pairs]
        answers = [a for _, a in pairs]
        print(f"bank_chatbot_data.csv 로드 완료 ({len(pairs)} pairs)")
    else:
        print("my_txts 폴더도 비어있고 CSV도 없습니다.")
        pairs = []
        questions = []
        answers = []
        bank_mtime = 0

# ------------------------------------------
# 2. Load SBERT Embedding
# ------------------------------------------

MODEL_ID_Sbert = 'snunlp/KR-SBERT-V40K-klueNLI-augSTS'
embedder = SentenceTransformer(MODEL_ID_Sbert).to(device)

CACHE_VEC = "question_vec.pt"
CACHE_META = "question_vec.meta.json"
need_rebuild = True

if questions:
    if os.path.exists(CACHE_VEC) and os.path.exists(CACHE_META):
        meta = json.load(open(CACHE_META, encoding="utf-8"))
        if meta.get("bank_mtime") == bank_mtime and meta.get("num_q") == len(questions):
            need_rebuild = False

    if need_rebuild:
        print("SBERT 임베딩 재계산 중...")
        q_vec = embedder.encode(questions, convert_to_tensor=True)
        torch.save(q_vec.cpu(), CACHE_VEC)
        json.dump(
            {"bank_mtime": bank_mtime, "num_q": len(questions)},
            open(CACHE_META, "w", encoding="utf-8")
        )
        print("임베딩 캐시 저장 완료!")
    else:
        q_vec = torch.load(CACHE_VEC, map_location=device)
        print("임베딩 캐시 로드 완료!")
else:
    q_vec = None

# ------------------------------------------
# 3. 인사말 룰
# ------------------------------------------

greet = {
    "안녕": "안녕하세요! 무엇을 도와드릴까요?",
    "안녕하세요": "안녕하세요! 무엇을 도와드릴까요?",
    "하이": "안녕하세요! 편하게 질문해 주세요.",
    "좋은 아침이에요": "좋은 아침입니다! 무엇을 도와드릴까요?",
    "너는 누구야": "저는 부산은행 챗봇입니다. 궁금하신 내용을 말씀해 주세요!"
}

# ------------------------------------------
# 4. 챗봇 함수
# ------------------------------------------

def chat_with_bot(user_text):
    user_text = user_text.strip()

    # 인사말 처리
    if user_text in greet:
        return greet[user_text]

    if not questions:
        return "아직 학습된 FAQ가 없습니다. 관리자에게 문의하세요."

    # SBERT로 유사도 계산
    user_vec = embedder.encode(
        user_text,
        convert_to_tensor=True,
        device=device
    )

    cosine_scores = util.cos_sim(user_vec, q_vec)
    max_score = cosine_scores.max().item()

    # Threshold 체크
    THRESH = 0.5
    if max_score < THRESH:
        return "죄송합니다. 이해하지 못했어요. 조금 다르게 질문해 주실 수 있을까요?"

    # Top-N 결과 추천
    top_n = 3
    top_indices = torch.topk(cosine_scores.squeeze(), top_n).indices.tolist()

    response_text = "혹시 아래 중 어떤 내용이 궁금하신가요?\n"
    for idx in top_indices:
        score = cosine_scores[0, idx].item()
        response_text += f"- {questions[idx]} → {answers[idx]} \n\n"

    return response_text



def reload_vectors():
    global pairs, questions, answers, q_vec, bank_mtime, embedder

    if os.path.exists("bank_chatbot_data.csv"):
        df = pd.read_csv("bank_chatbot_data.csv")
        pairs = list(zip(df["input_text"], df["target_text"]))
        questions = [q for q, _ in pairs]
        answers = [a for _, a in pairs]

        if questions:
            embedder = SentenceTransformer(MODEL_ID_Sbert).to(device)
            q_vec = embedder.encode(questions, convert_to_tensor=True)
            torch.save(q_vec.cpu(), CACHE_VEC)
            json.dump(
                {"bank_mtime": os.path.getmtime("bank_chatbot_data.csv"), "num_q": len(questions)},
                open(CACHE_META, "w", encoding="utf-8")
            )
            bank_mtime = os.path.getmtime("bank_chatbot_data.csv")
            print("임베딩 리로드 완료!")
        else:
            q_vec = None
            print("질문 데이터가 없습니다.")
    else:
        print("CSV 파일이 없습니다.")
