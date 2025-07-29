# train_card_from_db.py

import cx_Oracle
import pandas as pd
import os
import datetime
import pickle
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

load_dotenv()
TRAIN_LOG_PATH = "data/last_trained.log"
VECTOR_SAVE_PATH = "data/card_vectors.pkl"

def get_card_data():
    conn = cx_Oracle.connect("bank/1234@localhost:1521/Bank")
    cur = conn.cursor()
    cur.execute("""
        SELECT CARD_NO, CARD_NAME, CARD_TYPE, CARD_BRAND, ANNUAL_FEE, ISSUEDTO, SERVICE, 
             S_SERVICE, CARD_SLOGAN, CARD_NOTICE, CARD_URL
        FROM CARD
        WHERE CARD_STATUS IN ('게시중', '정상')
    """)

    # LOB 강제 문자열로 변환
    rows = []
    for row in cur:
        row = list(row)
        for i, val in enumerate(row):
            if hasattr(val, 'read'):  # LOB 객체면 read()
                row[i] = val.read()
        rows.append(row)

    columns = [desc[0] for desc in cur.description]
    df = pd.DataFrame(rows, columns=columns)
    cur.close()
    conn.close()
    return df

BASE_URL = "http://localhost:8090/cards/detail?no="   # 상세 페이지 Prefix

def row_to_text(row):
    detail_url = f"{BASE_URL}{row['CARD_NO']}"        # ★ 카드번호로 링크 생성
    return (
        f"카드명: {row['CARD_NAME']} | "
        f"유형: {row['CARD_TYPE']} | "
        f"브랜드: {row['CARD_BRAND']} | "
        f"연회비: {row['ANNUAL_FEE']}원 | "
        f"대상: {row['ISSUEDTO']} | "
        f"주요 혜택: {row['SERVICE']} | "
        f"부가 혜택: {row['S_SERVICE']} | "
        f"링크: {detail_url}"
    )


def run_full_card_training():
    os.makedirs("data", exist_ok=True) 
    df = get_card_data()
    if df.empty:
        return "[ERROR] 카드 데이터 없음"

    model = SentenceTransformer("sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
    texts = df.apply(row_to_text, axis=1).tolist()
    vectors = model.encode(texts, convert_to_tensor=False)

    with open(VECTOR_SAVE_PATH, "wb") as f:
        pickle.dump({
            "texts": texts,
            "vectors": vectors,
            "data": df.to_dict(orient="records")
        }, f)

    with open(TRAIN_LOG_PATH, "w", encoding="utf-8") as f:
        f.write(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    print(f"[INFO] 카드 {len(df)}건 학습 완료 → 벡터 저장: {VECTOR_SAVE_PATH}")

def get_last_training_time():
    try:
        with open(TRAIN_LOG_PATH, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return "아직 학습된 이력이 없습니다."
