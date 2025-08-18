from facenet_pytorch import InceptionResnetV1, MTCNN
from PIL import Image
import torch

# 전역 1회 초기화
_mtcnn = MTCNN(image_size=160, margin=0)
_resnet = InceptionResnetV1(pretrained='vggface2').eval()

def _get_embedding(img_path: str):
    img = Image.open(img_path).convert("RGB")
    face = _mtcnn(img)
    if face is None:
        raise ValueError("얼굴 검출 실패")
    with torch.no_grad():
        return _resnet(face.unsqueeze(0))  # (1,512)

def verify_face(id_path: str, face_path: str, threshold: float = 0.90) -> bool:
    emb1 = _get_embedding(id_path)
    emb2 = _get_embedding(face_path)
    sim = torch.nn.functional.cosine_similarity(emb1, emb2).item()
    print(f"[Face] cosine similarity = {sim:.4f}")
    return sim >= threshold
