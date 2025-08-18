import easyocr
import re

def extract_rrn(id_path: str) -> str | None:
    """
    신분증 이미지에서 주민등록번호 추출
    - 정상: 123456-1234567
    - 마스킹: 123456-1******
    """
    reader = easyocr.Reader(['ko', 'en'])
    results = reader.readtext(id_path)

    for _, text, _ in results:
        # 1) 완전 주민번호 패턴
        match_full = re.search(r"\d{6}-\d{7}", text)
        if match_full:
            return match_full.group()

        # 2) 마스킹 패턴 (예: 123456-1******)
        match_masked = re.search(r"\d{6}-\d\*{6}", text)
        if match_masked:
            return match_masked.group()

    return None
