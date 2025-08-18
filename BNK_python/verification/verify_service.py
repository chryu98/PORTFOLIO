import os
from verification.id_service import extract_rrn
from verification.face_service import verify_face

def verify_identity(id_path, face_path, expected_rrn: str):
    """
    본인인증 전체 프로세스
    1. 신분증 OCR → 주민번호 추출
    2. 기대값과 비교 (마스킹 지원)
    3. 얼굴 비교
    4. 파일 파기
    """
    try:
        # 1. 주민번호 추출
        rrn = extract_rrn(id_path)

        if rrn is None:
            cleanup([id_path, face_path])
            return {"status": "FAIL", "reason": "주민번호 인식 실패"}

        # 2. 뒷자리 비교 (마스킹 지원)
        expected_back = expected_rrn[-7:]
        if "*" in rrn:  # 마스킹된 경우
            if not rrn.startswith(expected_rrn[:8]):  # 앞 7자리 + 성별 코드 비교
                cleanup([id_path, face_path])
                return {"status": "FAIL", "reason": "주민번호 불일치(마스킹)"}
        else:  # 완전 주민번호
            if rrn[-7:] != expected_back:
                cleanup([id_path, face_path])
                return {"status": "FAIL", "reason": "주민번호 불일치"}

        # 3. 얼굴 비교
        face_ok = verify_face(id_path, face_path)
        cleanup([id_path, face_path])

        if not face_ok:
            return {"status": "FAIL", "reason": "얼굴 불일치"}

        return {"status": "PASS", "reason": "본인인증 성공"}

    except Exception as e:
        cleanup([id_path, face_path])
        return {"status": "ERROR", "reason": str(e)}

def cleanup(files):
    """ 파일 즉시 삭제 """
    for f in files:
        if os.path.exists(f):
            os.remove(f)
