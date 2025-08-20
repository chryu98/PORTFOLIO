# verification/face_service.py
from facenet_pytorch import InceptionResnetV1, MTCNN
from PIL import Image
import torch, io

_mtcnn = MTCNN(image_size=160, margin=0)
_resnet = InceptionResnetV1(pretrained='vggface2').eval()

def _emb_from_bytes(file_bytes: bytes):
    img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
    face = _mtcnn(img)  # tensor or None
    if face is None:
        raise ValueError("얼굴 검출 실패")
    with torch.no_grad():
        return _resnet(face.unsqueeze(0))  # (1,512)

def verify_face(id_bytes: bytes, face_bytes: bytes, threshold: float = 0.90) -> bool:
    emb1 = _emb_from_bytes(id_bytes)
    emb2 = _emb_from_bytes(face_bytes)
    sim = torch.nn.functional.cosine_similarity(emb1, emb2).item()
    print(f"[Face] cosine similarity = {sim:.4f}")
    return sim >= threshold
