# MoDit (2025 캡스톤디자인)
> 팀명: **사공사**

<img src="https://github.com/user-attachments/assets/60a37c32-10dc-4c77-9921-d06dbd9d7623" width="300"/>


## [작품 개요]
**📚 그룹스터디 최적화 올인원 협업 플랫폼**

> **모딧(Modit)** 은 음성 녹음 텍스트화, 손글씨 인식, AI 요약 기능을 결합해 회의록과 학습 자료를 직접 생성·공유할 수 있는 그룹 스터디 특화 올인원 플랫폼입니다. 앱 내에서 과제를 직접 작성하고 공유할 수 있어 협업 효율이 높고, 반복적인 기록 작업을 줄여 학습과 팀플에 집중할 수 있습니다.


## [주요 적용 기술 및 구조]

- **주요 기술**:  
  - OpenAI (ChatGPT)  
  - Naver Clova Speech API  
  - Google Cloud Vision OCR API  

- **개발 언어**: Dart, Python  
- **개발 환경**: Windows  
- **개발 도구**: Android Studio, VSCode, Firebase, Amazon EC2  

- **프레임워크 및 API**:  
  - Flutter  
  - Flask  
  - OpenAI API  
  - NAVER Cloud Platform (Clova API + Object Storage)  
  - Google Cloud Vision API
 
- **구조**
  
  ![구조](https://github.com/user-attachments/assets/3929c0cb-469d-4392-84c5-197cd16cf5df)

---

## 📱 MoDitApp (Flutter)
> MoDit 프로젝트의 프론트엔드 앱

Flutter 기반 태블릿 전용 앱으로, 사용자 인터페이스와 Firebase 실시간 연동을 통해 그룹별 과제, 회의록, 메모, 채팅, 공부 시간 등을 통합 관리할 수 있습니다.

### 핵심 기능
- 노트
- 과제 제출 및 관리
- 미팅 일정 관리 및 회의 녹음(요약)
- 공지사항
- 채팅

### 🚀 시작하기
AI 기능이 탑재된 Flask 백엔드와 연동되어, **손글씨 OCR**, **음성 텍스트 변환**, **텍스트 요약** 기능을 수행합니다.

- Flutter 3.x 기반으로 개발  
- Firebase 연동 (인증, 실시간 데이터베이스, 저장소)  
- Flask REST API와 통신 (OCR, 음성 인식, 자연어 처리)


## 🧠 MoDitFlask (Python Flask Backend)
> AI 기능 연산 및 Firebase와 연동되는 서버 백엔드


### 핵심 기능
- 이미지 파일 -> **Google Cloud Vision OCR Api**를 사용해 손글씨를 텍스트화
- 음성 파일 -> **Clova speech Api**를 사용해 음성 녹음을 텍스트화
- 텍스트 및 이미지 파일 -> **OpenAI(GPT) Api**를 사용해 노트 및 음성 텍스트를 요약
- 결과는 **Naver Object Storage**에 저장
  
### Integration
Flutter 앱은 Flask 서버에 HTTP 요청을 보내며 다음과 같이 연동됩니다:

- 이미지 업로드 → Flask OCR → 결과 텍스트를 Firebase에 저장  
- 음성 녹음 파일 업로드 → Flask Naver Clova Speech Recognition API → 결과 텍스트 저장  
- 메모 or 필기 텍스트 → Flask Summarization → 요약 텍스트 저장

---
  ## 🎯 기대 효과
  **1. 플랫폼 분산 해소**  
        - 노션, 밴드 등 여러 앱을 오가는 번거로움을 없애고, 통합된 협업 플랫폼 제공  
  
  **2. 실시간 저장 및 공유**  
        - 회의 및 학습 내용을 실시간 저장·공유하여 팀 내 정보 격차 해소  
  
  **3. 지속 가능한 협업 환경 제공**  
        - 학습 몰입도와 협업 생산성을 동시에 끌어올리는 스마트 플랫폼  

---

## 🖼️ 작품 소개 사진

![작품사진](https://github.com/user-attachments/assets/493190c2-3a59-4bc4-a1fc-f24d8bb53bdc)

