# BNK Card 프로젝트  
![Java](https://img.shields.io/badge/Java-21-007396?style=for-the-badge&logo=openjdk&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Oracle](https://img.shields.io/badge/Oracle-DB-F80000?style=for-the-badge&logo=oracle&logoColor=white)
![Python](https://img.shields.io/badge/Python-FastAPI-3776AB?style=for-the-badge&logo=python&logoColor=white)
![AI](https://img.shields.io/badge/AI-YOLOv8%20%7C%20EasyOCR%20%7C%20FaceNet-111111?style=for-the-badge)


## AI 기반 부산은행 카드 발급 및 관리 플랫폼

BNK Card는 Spring Boot, Flutter, Oracle, Python 기반으로 구현한  
**하이브리드 금융 서비스 포트폴리오 프로젝트**입니다.  

웹과 모바일 전반의 UI를 **UX 기반으로 재설계**하여  
사용자가 한눈에 서비스를 이해하고,  
불필요한 화면 이동 없이도 카드 발급과 관리를 완료할 수 있도록  
**매끄러운 사용자 흐름 중심의 금융 서비스**로 설계했습니다.

---

## 1. 프로젝트 개요

BNK Card는 사용자의 카드 신청부터 발급, 관리까지의 전 과정을  
디지털로 통합한 모바일·웹 금융 서비스입니다.

본 프로젝트에서는 단순한 기능 구현을 넘어  
- **웹·앱 전반 UI 구조를 UX 관점에서 재정비**하고  
- 카드 발급 과정의 복잡도를 줄이기 위해 **단계형 플로우로 시각화**했으며  
- AI 기능을 서비스 흐름에 자연스럽게 녹여  
  사용성 향상과 보안 강화를 동시에 달성하는 것을 목표로 했습니다.

### 프로젝트 핵심 목표
- 웹·모바일 전반 UI를 UX 중심으로 개선  
- 화면 이동을 최소화한 **집중형 사용자 흐름 설계**  
- 카드 발급 이탈률 감소를 위한 단계별 UX 최적화  
- AI 기능을 서비스 맥락에 맞게 연동한 자동화 구조 구현  

---

## 2. 기술 스택

| 구분 | 사용 기술 |
|---|---|
| Frontend | Flutter |
| Backend | Spring Boot (Java 21) |
| Database | Oracle |
| AI Server | Python (FastAPI) |
| Infra / 기타 | Gradle, Lombok, WebSocket/STOMP, SSE, OpenAPI |
| AI Model | YOLOv8, OCR, Face Recognition, Sentiment Analysis |

---

## 3. 아키텍처 구성

[Flutter App / Web UI]
↕
[Spring Boot Server] ↔ [Oracle DB]
↕ (REST API)
[Python AI Server]
├─ OCR 및 얼굴 인식 검증
├─ 이미지 검열 (YOLO)
└─ 사용자 피드백 감정 분석

yaml
코드 복사

- UI/UX 흐름은 Spring 서버를 중심으로 통합 제어  
- AI 서버는 검증·분석 전담 역할로 분리  
- 웹과 앱이 동일한 발급 흐름을 공유하도록 설계  

---

## 4. 주요 기능

| 구분 | 기능 설명 |
|---|---|
| 회원 및 보안 | 본인 인증, 로그인/세션 관리 |
| 카드 발급 절차 | 약관 동의 → 정보 입력 → AI 인증 → 배송지 입력 → PIN 설정 → 전자서명 |
| 커스텀 카드 | 카드 디자인 편집 및 이미지 검열 연동 |
| 챗봇 | 카드 상품·혜택·발급 상담, 실시간 상담 연결 |
| 피드백 분석 | 사용자 리뷰 수집 및 감정 분석 통계 |
| 위치 기반 서비스 | GPS 기반 영업점 검색 및 지도 표시 |
| 관리자 페이지 | 고객·약관·추천상품·리포트·이탈률 관리 |

---

## 5. AI 기능 활용 (서비스 연동 관점)

| 기능 | 설명 |
|---|---|
| 이미지 검열 | 커스텀 카드 이미지 업로드 시 AI 서버 연동 검증 |
| 본인 인증 | OCR 결과 + 얼굴 인식 결과를 발급 로직에 반영 |
| 감정 분석 | 사용자 피드백을 분석하여 관리자 리포트로 제공 |

> AI 기술은 단독 기능이 아닌  
> **UX 흐름을 방해하지 않는 보조 수단**으로 활용했습니다.

---

## 6. UX 설계 방향 (중점 개선 사항)

- **한눈에 들어오는 정보 구조**  
  → 카드 발급 단계, 현재 위치, 다음 행동을 명확히 시각화  
- **이동 최소화 UX**  
  → 불필요한 페이지 전환 제거, 핵심 기능 집중 배치  
- **단계형 발급 플로우**  
  → 사용자가 현재 단계와 남은 단계를 직관적으로 인지  
- **즉시 피드백 UX**  
  → 입력 오류·검증 실패 시 인라인 메시지 제공  
- **웹·앱 UI 일관성 유지**  
  → 동일한 발급 흐름과 인터랙션 구조 설계  
- **이탈 방지 설계**  
  → 정책 제한·주의사항을 경고가 아닌 UX 메시지로 안내  

---

## 7. 담당 역할 및 기여도

### 🟢 창훈 (카드 발급 프로세스 / 웹·앱 UI·UX 설계 / 통계 구조)

- **카드 발급 전체 흐름 UX 설계 및 구조 개선**
- 웹·모바일 전반 UI를 UX 관점에서 재설계
- 불필요한 화면 이동을 줄인 **집중형 발급 플로우 구현**
- 발급 단계별 상태 관리 및 통계 구조 설계
- Spring Boot 기반 카드 발급 API 구현
- Flutter 앱과 웹 UI의 발급 흐름 통합 설계
- 사용자 이탈률 감소를 목표로 한 UX 개선 주도

---

### 김성훈
- AI 이미지 검열
- SSE 기반 푸시 알림
- 리뷰 피드백 분석

### 수현
- 회원 및 상품 관리
- 약관 뷰어
- PDF / Excel 보고서 기능

### 민수
- 위치 기반 영업점 안내
- 커스텀 카드 UI

### 대영
- 추천 상품 관리
- 공통 / 개별 약관 등록 및 관리

---

## 8. 관리자 기능 요약

| 기능 | 설명 |
|---|---|
| 고객 관리 | 신청 이력, 발급 상태, 이탈 단계 추적 |
| 약관 관리 | PDF 업로드, 사용 여부, 버전 관리 |
| 추천 상품 | 클릭·신청 데이터 기반 추천 카드 운영 |
| 리포트 | Excel / PDF 출력 |
| 이탈률 분석 | 발급 단계별 전환율 시각화 |

---

## 9. 성과 및 개선 사항

### 성과
- 웹·앱 UI를 UX 중심으로 재설계하여 사용 흐름 개선
- 카드 발급 단계별 이탈 요인을 구조적으로 분석
- AI 기능을 UX 흐름을 해치지 않는 방식으로 연동
- 사용자·관리자 관점을 모두 반영한 금융 서비스 구조 완성

### 개선 방향
- 실사용 데이터 기반 UX A/B 테스트 도입
- 발급 단계별 실시간 알림 및 리텐션 기능 강화
- 관리자 대시보드 시각화 고도화

---

## 10. 프로젝트를 통해 배운 점

- 금융 서비스에서는 **화면보다 흐름이 더 중요**하다는 점
- UX 설계의 작은 차이가 사용자 이탈로 직결됨
- 웹과 앱을 하나의 사용자 경험으로 설계하는 중요성
- 기능 구현보다 **사용성·운영 관점 설계**가 핵심임을 체감

---

## 11. 실행 환경 요약

| 항목 | 설정 |
|---|---|
| Spring Server | http://localhost:8090 |
| AI Server | http://localhost:8000 / 8001 |
| DB | Oracle XE |
| App Test | Android Emulator / Web |

---

## 12. 디렉토리 구조

BNK_spring/
BNKAndroid/
python-ai-server/

yaml
코드 복사

---

## 13. 향후 계획

- 사용자 행동 데이터 기반 UX 개선
- 실시간 이벤트 알림 및 발급 리텐션 강화
- 관리자 운영 대시보드 확장
- UX 중심 서비스 고도화

---

**Last Updated:** 2025.10  
**Author:** 류창훈
