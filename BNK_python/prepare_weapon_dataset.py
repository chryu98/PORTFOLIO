import os
import zipfile
import subprocess
from pathlib import Path

# Kaggle dataset 경로 (칼+총 YOLO용)
KAGGLE_DATASET = "raghavnanjappan/weapon-dataset-for-yolov5"

# 현재 프로젝트 기준 경로
ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data" / "weapon_dataset"
ZIP_FILE = ROOT / "weapon-dataset-for-yolov5.zip"

def ensure_kaggle():
    """ Kaggle CLI 설치 여부 확인 """
    try:
        subprocess.run(["kaggle", "--version"], check=True, capture_output=True)
        print("[INFO] Kaggle CLI is 설치됨")
    except subprocess.CalledProcessError as e:
        print("[ERROR] Kaggle CLI 실행 실패:", e)
    except FileNotFoundError:
        print("[ERROR] Kaggle CLI가 설치되어 있지 않음. 먼저 `pip install kaggle` 실행하세요.")
        exit(1)

def download_dataset():
    """ Kaggle dataset 다운로드 """
    if ZIP_FILE.exists():
        print(f"[INFO] 이미 zip 파일이 존재: {ZIP_FILE}")
        return

    print(f"[INFO] Kaggle에서 데이터셋 다운로드 중: {KAGGLE_DATASET}")
    subprocess.run([
        "kaggle", "datasets", "download", "-d", KAGGLE_DATASET
    ], check=True)
    print("[INFO] 다운로드 완료")

def unzip_dataset():
    """ 압축 풀기 """
    if DATA_DIR.exists():
        print(f"[INFO] {DATA_DIR} 이미 존재함, 건너뜀")
        return

    print(f"[INFO] {ZIP_FILE} 압축 해제 중...")
    with zipfile.ZipFile(ZIP_FILE, "r") as zip_ref:
        zip_ref.extractall(DATA_DIR)
    print(f"[INFO] 압축 해제 완료: {DATA_DIR}")

def check_structure():
    """ train/val/test 구조 확인 """
    expected = [
        DATA_DIR / "images" / "train",
        DATA_DIR / "images" / "val",
        DATA_DIR / "labels" / "train",
        DATA_DIR / "labels" / "val",
    ]
    ok = True
    for p in expected:
        if not p.exists():
            print(f"[WARN] {p} 없음 ❌")
            ok = False
        else:
            print(f"[OK] {p} ✅ ({len(list(p.glob('*')))} files)")
    return ok

if __name__ == "__main__":
    ensure_kaggle()
    download_dataset()
    unzip_dataset()
    if check_structure():
        print("[SUCCESS] weapon_dataset 준비 완료! 이제 학습을 시작할 수 있습니다 🚀")
    else:
        print("[ERROR] 데이터셋 구조가 올바르지 않습니다. 직접 확인해 주세요.")
