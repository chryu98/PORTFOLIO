# verification/verify_service.py
from verification.id_service import extract_rrn
from verification.face_service import verify_face
import logging

log = logging.getLogger("verify")


def _parse_expected(rrn: str):
    """expected_rrn 문자열(완전/마스킹)을 내부 포맷으로 파싱"""
    s = rrn.strip().replace(" ", "")
    # 다양한 대쉬를 통일
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

    # 마스킹 모드 여부(*, x, X 허용)
    masked = any(ch in tail for ch in ["*", "x", "X"])
    return {"front": front, "gender": gender, "tail": None if masked else tail, "masked": masked}


def _mask_front(front: str) -> str:
    """앞 2자리만 노출하고 나머지는 마스킹"""
    if not front:
        return ""
    return f"{front[:2]}****"


def verify_identity(id_bytes: bytes, face_bytes: bytes, expected_rrn: str):
    """
    - 신분증 이미지에서 주민번호 OCR
    - expected_rrn(완전 또는 마스킹)과 비교
    - 얼굴 매칭(FAIL/사유 포함)
    """
    # 1) OCR 수행
    try:
        ocr = extract_rrn(id_bytes)  # {'front','gender','tail','masked','preview'}
    except Exception as e:
        return {"status": "ERROR", "reason": f"OCR 실패: {e}"}

    # 2) expected_rrn 파싱
    try:
        exp = _parse_expected(expected_rrn)
    except Exception as e:
        return {
            "status": "ERROR",
            "reason": f"expected_rrn 형식 오류: {e}",
            "ocr": {"preview": ocr.get("preview", "")},
        }

    # 🔎 콘솔/파일 로그: 앞번호(마스킹) + 길이만 남김
    ocr_front = str(ocr.get("front", ""))
    exp_front = str(exp.get("front", ""))
    log.info(
        f"[RRN] OCR front={_mask_front(ocr_front)} len={len(ocr_front)} | "
        f"EXP front={_mask_front(exp_front)} len={len(exp_front)}"
    )

    # 3) 주민번호 일치 여부
    rrn_ok = (
        ocr["front"] == exp["front"]
        and ocr["gender"] == exp["gender"]
        and (
            exp["tail"] is None  # 마스킹 모드면 뒷자리 비교 생략
            or (ocr["tail"] != "******" and ocr["tail"] == exp["tail"])  # 완전비교
        )
    )

    # 4) 얼굴 매칭
    face_ok = False
    face_reason = None
    try:
        face_ok = verify_face(id_bytes, face_bytes)  # True/False
    except Exception as e:
        face_reason = str(e)

    # 5) 최종 결과
    status = "PASS" if (rrn_ok and face_ok) else "FAIL"
    reasons = []
    if not rrn_ok:
        reasons.append("주민번호 불일치/미인식")
    if not face_ok:
        reasons.append(face_reason or "얼굴 불일치/미검출")

    return {
        "status": status,
        "reason": ", ".join(reasons) if reasons else "OK",
        "ocr": {"preview": ocr.get("preview", "")},   # 원문 미노출
        "checks": {"rrn": rrn_ok, "face": face_ok},   # 보조 정보
    }
