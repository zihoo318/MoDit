# MoDit (2025 캡스톤디자인)

## MoDitApp (Flutter)
> 2025 캡스톤디자인 프로젝트의 프론트엔드 앱

### Getting Started
This project is the starting point for the Flutter-based client application for **MoDit**.  
It integrates with an AI-powered Flask backend for OCR, voice-to-text, and summarization.

- Built with Flutter 3.x  
- Integrated with Firebase (Auth, Firestore, Storage)  
- Works with Flask REST API (OCR, STT, NLP)

---

## MoDitFlask (Python Flask Backend)
> AI 기능 연산 및 Firebase와 연동되는 서버 백엔드

### Features
- **Voice Transcription** using Naver Clova Speech API  
- **OCR (Image-to-Text)** using local pretrained models  
- **Text Summarization** using local Phi model  
- All output files (text results) are stored into **Firebase Storage**

## Integration
Flutter 앱은 Flask 서버에 HTTP 요청을 보내며 다음과 같이 연동됩니다:

- 이미지 업로드 → Flask OCR → 결과 텍스트를 Firebase에 저장  
- 음성 녹음 파일 업로드 → Flask Naver Clova Speech Recognition API → 결과 텍스트 저장  
- 메모 or 필기 텍스트 → Flask Summarization → 요약 텍스트 저장
