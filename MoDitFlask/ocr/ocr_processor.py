# ocr/ocr_processor.py
from google.cloud import vision
import io, cv2
from pathlib import Path
import os
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/home/ubuntu/modit_docu/regal-dynamo-459905-a6-33e9e8214e12.json"


def preprocess_image(image_path):
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    enhanced = cv2.equalizeHist(gray)
    temp_path = Path(image_path).with_name("preprocessed.jpg")
    cv2.imwrite(str(temp_path), enhanced)
    return str(temp_path)

def run_ocr(image_path):
    # 이미지 전처리
    preprocessed_path = preprocess_image(image_path)

    # Vision API 클라이언트 생성
    client = vision.ImageAnnotatorClient()

    with io.open(preprocessed_path, 'rb') as image_file:
        content = image_file.read()

    image = vision.Image(content=content)

    # 문서 형태로 OCR 실행 (단어, 문단 구분됨)
    response = client.document_text_detection(
        image=image,
        image_context={"language_hints": ["ko"]}  # 한국어 인식 최적화
    )

    # 에러 확인
    if response.error.message:
        raise Exception(f'OCR API Error: {response.error.message}')

    # 전체 텍스트 추출
    texts = response.full_text_annotation.text
    print("📄 인식 결과:\n", texts)
    return texts
