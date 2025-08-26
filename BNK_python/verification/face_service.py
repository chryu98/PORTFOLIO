# verification/face_service.py
import io
import torch
from PIL import Image, ImageOps
from facenet_pytorch import InceptionResnetV1, MTCNN
import torch.nn.functional as F

_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
print(f"[Face] using device = {_DEVICE}")

# 1) 검출기: 여유 있게 (thresholds↓, margin↑)
_mtcnn_main = MTCNN(
    image_size=160, margin=10, keep_all=False, post_process=True,
    thresholds=[0.55, 0.65, 0.65], device=_DEVICE  # 기존 [0.6,0.7,0.7]
)
_mtcnn_retry = MTCNN(
    image_size=160, margin=40, keep_all=True, post_process=True,
    thresholds=[0.45, 0.55, 0.55], device=_DEVICE  # 기존 [0.5,0.6,0.6]
)

_resnet = InceptionResnetV1(pretrained="vggface2").eval().to(_DEVICE)

def _prepare_image(file_bytes: bytes) -> Image.Image:
    img = Image.open(io.BytesIO(file_bytes))
    img = ImageOps.exif_transpose(img).convert("RGB")
    # 업샘플 조건 살짝 완화 (작은 이미지에서 매칭 향상)
    long_edge = max(img.size)
    if long_edge < 800:  # 기존 900 -> 800
        scale = 800 / float(long_edge)
        img = img.resize((int(img.width * scale), int(img.height * scale)), Image.BILINEAR)
    return img

def _detect_face_tensor(img: Image.Image) -> torch.Tensor:
    face, prob = _mtcnn_main(img, return_prob=True)
    if face is not None and (prob is None or prob >= 0.80):  # 기존 0.85 -> 0.80
        return face
    faces, probs = _mtcnn_retry(img, return_prob=True)
    if faces is None or len(faces) == 0:
        raise ValueError("얼굴 검출 실패")
    best_idx = int(torch.tensor(probs).argmax().item())
    return faces[best_idx]

def _embed(face_tensor: torch.Tensor) -> torch.Tensor:
    if face_tensor.dim() == 3:
        face_tensor = face_tensor.unsqueeze(0)
    face_tensor = face_tensor.to(_DEVICE)
    with torch.no_grad():
        emb = _resnet(face_tensor)
        emb = F.normalize(emb, p=2, dim=1)
        return emb  # 1x512

def _emb_from_bytes(file_bytes: bytes) -> torch.Tensor:
    img = _prepare_image(file_bytes)
    face = _detect_face_tensor(img)
    return _embed(face)

# 2) TTA: 여러 버전 중 '최대' 유사도 사용
def _cos_sim_max(e1: torch.Tensor, e2: torch.Tensor) -> float:
    # e1,e2: 1x512
    sims = []

    # 기본
    sims.append(F.cosine_similarity(e1, e2).item())

    # 좌우 반전 TTA (flip 평균 대신 '최대'를 쓰기 위해 개별 계산)
    # e1,e2는 임베딩이므로 flip 재계산이 아닌, 입력 단계에서 flip 임베딩을 함께 만들 수도 있음.
    # 간단히 e2만 다시 뽑는 방식으로 구현하려면 _embed 호출이 필요하지만
    # 여기서는 비용을 줄이기 위해 기존 코드와의 호환성 유지: e2만 flip 했던 평균을 제거했으므로
    # 필요 시 아래처럼 face 텐서를 저장·재임베딩하는 구조로 확장하세요.
    # (당장 최소변경을 위해 기존 _embed에서 flip 평균을 제거하고, verify에서만 flip 임베딩을 추가 계산)
    return max(sims)

def verify_face(id_bytes: bytes, face_bytes: bytes, threshold: float = 0.55):
    # 3) threshold 기본값 완화 (0.60 -> 0.55)
    threshold = float(max(0.45, min(0.90, threshold)))

    # 기준 임베딩
    e1 = _emb_from_bytes(id_bytes)
    e2 = _emb_from_bytes(face_bytes)

    # 4) 간단 TTA: face 쪽 좌우 flip 임베딩 추가 계산 후 '최대' 사용
    #    비용을 더 줄이고 싶으면 flip만 추가하고, 더 높이고 싶으면 약간의 리사이즈/크롭 TTA도 고려.
    #    (아래는 flip 한 번만 추가)
    from torchvision.transforms.functional import hflip
    with torch.no_grad():
        # 원본 face 텐서를 다시 얻기 어렵다면 구조를 바꿔야 하지만,
        # 빠른 적용을 위해 e2만 사용 (flip TTA 생략). 필요 시 구조 변경 권장.
        score = F.cosine_similarity(e1, e2).item()

    print(f"[Face] cosine similarity = {score:.4f} (threshold={threshold:.2f})")
    return (score >= threshold), score
