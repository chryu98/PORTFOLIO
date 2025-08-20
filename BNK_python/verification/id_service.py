import re
import io
import numpy as np
import cv2
from easyocr import Reader

# 한/영 모델 로컬 추론
_reader = Reader(['ko', 'en'], gpu=False)

# 대쉬·별표·공백 등 정규화
def _normalize(s: str) -> str:
    # 다양한 dash(‐-–—)를 일반 하이픈으로 통일
    s = re.sub(r"[‐-–—−]", "-", s)
    # 전각 별표 포함 통일
    s = s.replace("＊", "*")
    # 다중 공백 축소
    s = re.sub(r"\s+", " ", s)
    return s.strip()

def _decode_image(file_bytes: bytes):
    arr = np.frombuffer(file_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("이미지 디코드 실패(손상/미지원 포맷)")
    return img

def _preprocess_variants(img_bgr):
    """여러 전처리 버전 생성해서 순차 시도"""
    variants = []

    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    # 1) 기본 대비 보정
    v1 = cv2.bilateralFilter(gray, 7, 50, 50)
    v1 = cv2.equalizeHist(v1)
    variants.append(v1)

    # 2) 리사이즈(1.5x, 2x)
    for scale in (1.5, 2.0):
        v = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
        v = cv2.bilateralFilter(v, 7, 50, 50)
        variants.append(v)

    # 3) 적응형 이진화
    thr = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 25, 10
    )
    variants.append(thr)

    # 4) 역상 + 미세 팽창(얇은 획 보강)
    inv = 255 - thr
    kernel = np.ones((2, 2), np.uint8)
    inv = cv2.dilate(inv, kernel, iterations=1)
    variants.append(inv)

    return variants

# 주민번호 패턴(공백 허용 / 다양한 dash / 마스킹 허용)
# 예: 820701-234567  /  820701 - 2 3 4 5 6 7  /  820701-2******
RRN_FULL_FLEX = re.compile(
    r"(\d\s*\d\s*\d\s*\d\s*\d\s*\d)\s*[-]?\s*([1-4]\s*\d\s*\d\s*\d\s*\d\s*\d\s*\d)"
)
RRN_MASK_FLEX = re.compile(
    r"(\d\s*\d\s*\d\s*\d\s*\d\s*\d)\s*[-]?\s*([1-4])\s*[\*\×xX]\s*[\*\×xX]\s*[\*\×xX]\s*[\*\×xX]\s*[\*\×xX]\s*[\*\×xX]"
)

def _join_digits(s: str) -> str:
    """공백 섞인 숫자들 붙이기: '2 3 4 5 6 7' -> '234567'"""
    return re.sub(r"\s+", "", s)

def extract_rrn(file_bytes: bytes):
    img = _decode_image(file_bytes)
    candidates_text = []

    # allowlist: 숫자/하이픈/별표만 집중 인식
    allow = "0123456789-*＊xX"

    for v in _preprocess_variants(img):
        # EasyOCR는 numpy array도 받습니다.
        result = _reader.readtext(
            v,
            detail=1,
            paragraph=True,
            # 검출/인식 민감도 살짝 완화
            text_threshold=0.4,
            low_text=0.2,
            link_threshold=0.5,
            allowlist=allow,   # ★ 중요
            decoder="greedy",
        )
        txt = " ".join([t[1] for t in result]) if result else ""
        txt = _normalize(txt)
        if txt:
            candidates_text.append(txt)

        # 각 버전에서 바로 패턴 시도
        for pat in (RRN_FULL_FLEX, RRN_MASK_FLEX):
            m = pat.search(txt)
            if m:
                front = _join_digits(m.group(1))
                g = _join_digits(m.group(2))
                if pat is RRN_FULL_FLEX:
                    gender, tail = g[0], g[1:]
                    return {
                        "front": front,
                        "gender": gender,
                        "tail": tail,
                        "masked": False,
                        "preview": _mask_preview(front, gender, tail),
                    }
                else:
                    gender = g[0]
                    return {
                        "front": front,
                        "gender": gender,
                        "tail": "******",
                        "masked": True,
                        "preview": _mask_preview(front, gender, "******"),
                    }

    raise ValueError("주민번호 패턴 인식 실패")

def _mask_preview(front: str, gender: str, tail: str) -> str:
    """응답에 넣는 디버그용 안전 미리보기 (원문 노출 금지)"""
    tail_mask = tail if tail == "******" else "******"
    return f"{front}-{gender}{tail_mask}"
