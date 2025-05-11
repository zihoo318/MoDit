from dotenv import load_dotenv
import os

load_dotenv(dotenv_path='./config/key.env')  # .env 파일 경로 지정

# 환경변수 읽기
NCLOUD_ACCESS_KEY = os.getenv("NCLOUD_ACCESS_KEY")
NCLOUD_SECRET_KEY = os.getenv("NCLOUD_SECRET_KEY")
NCLOUD_BUCKET_NAME = os.getenv("NCLOUD_BUCKET_NAME")
NCLOUD_ENDPOINT = os.getenv("NCLOUD_ENDPOINT")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
NAVER_OCR_SECRET_KEY = os.getenv("NAVER_OCR_SECRET_KEY")
NAVER_STT_SECRET_KEY=os.getenv("NAVER_STT_SECRET_KEY")

