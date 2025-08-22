# verification/verify_service.py
from verification.id_service import extract_rrn
from verification.face_service import verify_face
import logging

log = logging.getLogger("verify")

def _parse_expected(rrn: str):
    s = rrn.strip().replace(" ", "")
    for d in ["‐", "–", "—", "−"]:
        s = s.replace(d, "-")

    if "-" in s:
        front, back = s.split("-", 1)
    else:
        front, back = s[:6], s[6:]

    if len(front) != 6 or len(back) < 1:
        raise ValueError("expected_rrn 형식 오류")

    gender = back[0]
    tail = back[1:] if len(back) > 1 else ""
    masked = any(ch in tail for ch in ["*", "x", "X"])
    return {"front": front, "gender": gender, "tail": None if masked else tail, "masked": masked}

def _mask_front(front: str) -> str:
    return f"{front[:2]}****" if front else ""

def verify_identity(id_bytes: bytes, face_bytes: bytes, expected_rrn: str, face_threshold: float = 0.6):
    # 1) OCR
    try:
        ocr = extract_rrn(id_bytes)  # {'front','gender','tail','masked','preview'}
    except Exception as e:
        return {"status": "ERROR", "reason": f"OCR 실패: {e}"}

    # 2) expected 파싱
    try:
        exp = _parse_expected(expected_rrn)
    except Exception as e:
        return {"status": "ERROR", "reason": f"expected_rrn 형식 오류: {e}", "ocr": {"preview": ocr.get("preview", "")}}

    # 최소 로그(앞 2자리 + 길이)
    ocr_front = str(ocr.get("front", ""))
    exp_front = str(exp.get("front", ""))
    log.info(f"[RRN] OCR front={_mask_front(ocr_front)} len={len(ocr_front)} | "
             f"EXP front={_mask_front(exp_front)} len={len(exp_front)}")

    # 3) 주민번호 비교 (expected tail이 마스킹이면 뒷자리 비교 생략)
    rrn_ok = (
        ocr["front"] == exp["front"]
        and ocr["gender"] == exp["gender"]
        and (exp["tail"] is None or (ocr["tail"] != "******" and ocr["tail"] == exp["tail"]))
    )

    # 4) 얼굴
    face_ok, face_score, face_err = False, None, None
    try:
        face_ok, face_score = verify_face(id_bytes, face_bytes, threshold=face_threshold)  # (bool, score)
    except Exception as e:
        face_err = str(e)

    status = "PASS" if (rrn_ok and face_ok) else "FAIL"
    reasons = []
    if not rrn_ok:
        reasons.append("주민번호 불일치/미인식")
    if not face_ok:
        reasons.append(face_err or (f"얼굴 불일치 (sim={face_score:.3f})" if face_score is not None else "얼굴 불일치/미검출"))

    return {
        "status": status,
        "reason": ", ".join(reasons) if reasons else "OK",
        "ocr": {"preview": ocr.get("preview", "")},
        "checks": {"rrn": rrn_ok, "face": face_ok, "face_score": face_score, "threshold": face_threshold},
    }
