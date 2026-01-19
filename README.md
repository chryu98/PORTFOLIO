# BNK Card 프로젝트  
Java · Spring Boot · Flutter · Oracle · Python · AI

## AI 기반 부산은행 카드 발급 및 관리 플랫폼

BNK Card는 Spring Boot, Flutter, Oracle, Python 기반으로 구현한  
**하이브리드 금융 서비스 포트폴리오 프로젝트**입니다.  
카드 발급 전 과정을 디지털로 통합하고,  
AI 기술을 실 서비스 흐름에 자연스럽게 결합하는 것을 목표로 설계했습니다.

---

## 1. 프로젝트 개요

BNK Card는 사용자의 카드 신청부터 발급, 관리까지의 전 과정을  
모바일 중심으로 통합한 금융 서비스입니다.

본 프로젝트에서는  
- 복잡한 카드 발급 절차를 **단계별 UX 플로우**로 구조화하고  
- AI 서버를 분리 연동하여 **본인 인증·이미지 검열·피드백 분석**을 자동화했으며  
- 사용자/관리자 관점을 모두 고려한 **운영형 금융 플랫폼 구조**를 구현했습니다.

### 프로젝트 핵심 목표
- 안전하고 효율적인 카드 발급 프로세스 구현  
- AI 기능을 서비스 흐름에 자연스럽게 통합  
- 사용자/관리자 통합 운영 시스템 설계  
- UX 마찰 최소화를 통한 이탈률 감소  

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

