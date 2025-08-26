# verification/face_service.py
import io
import torch
from PIL import Image, ImageOps
from facenet_pytorch import InceptionResnetV1, MTCNN
import torch.nn.functional as F

_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
print(f"[Face] using device = {_DEVICE}")

_mtcnn_main = MTCNN(image_size=160, margin=0, keep_all=False, post_process=True,
                    thresholds=[0.6, 0.7, 0.7], device=_DEVICE)
_mtcnn_retry = MTCNN(image_size=160, margin=20, keep_all=True, post_process=True,
                     thresholds=[0.5, 0.6, 0.6], device=_DEVICE)

_resnet = InceptionResnetV1(pretrained="vggface2").eval().to(_DEVICE)

def _prepare_image(file_bytes: bytes) -> Image.Image:
    img = Image.open(io.BytesIO(file_bytes))
    img = ImageOps.exif_transpose(img).convert("RGB")
    long_edge = max(img.size)
    if long_edge < 900:
        scale = 900 / float(long_edge)
        img = img.resize((int(img.width * scale), int(img.height * scale)), Image.BILINEAR)
    return img

def _detect_face_tensor(img: Image.Image) -> torch.Tensor:
    face, prob = _mtcnn_main(img, return_prob=True)
    if face is not None and (prob is None or prob >= 0.85):
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
        emb_flip = _resnet(torch.flip(face_tensor, dims=[3]))
        emb = (emb + emb_flip) / 2.0
        emb = F.normalize(emb, p=2, dim=1)
        return emb  # 1x512

def _emb_from_bytes(file_bytes: bytes) -> torch.Tensor:
    img = _prepare_image(file_bytes)
    face = _detect_face_tensor(img)
    return _embed(face)

def verify_face(id_bytes: bytes, face_bytes: bytes, threshold: float = 0.6):
    threshold = float(max(0.45, min(0.90, threshold)))
    e1 = _emb_from_bytes(id_bytes)
    e2 = _emb_from_bytes(face_bytes)
    score = F.cosine_similarity(e1, e2).item()
    print(f"[Face] cosine similarity = {score:.4f} (threshold={threshold:.2f})")
    return (score >= threshold), score
