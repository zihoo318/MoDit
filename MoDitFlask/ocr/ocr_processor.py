# ocr/ocr_processor.py
import requests, base64, json, time
from config import config_env  # 환경변수 import

def run_ocr(image_path):
    # api_url = "https://ua19fs219w.apigw.ntruss.com/custom/v1/41728/b515a54e0e45ae1263d136b254ace04d49882949d6b16032fc0637e0284168b8/general"
    # secret_key = config_env.NAVER_OCR_SECRET_KEY

    # with open(image_path, "rb") as image_file:
    #     image_data = base64.b64encode(image_file.read()).decode()

    # request_json = {
    #     "version": "V2",
    #     "requestId": str(int(time.time())),
    #     "timestamp": int(time.time() * 1000),
    #     "images": [
    #         {
    #             "name": "note-image",
    #             "format": "jpg",
    #             "data": image_data
    #         }
    #     ]
    # }

    # headers = {
    #     "X-OCR-SECRET": secret_key,
    #     "Content-Type": "application/json"
    # }

    # response = requests.post(api_url, headers=headers, data=json.dumps(request_json))
    # result = response.json()

    # print("📦 OCR API 응답 전체:")
    # print(json.dumps(result, indent=2, ensure_ascii=False))
    # print(f"📂 저장된 이미지 경로: {image_path}")

    # # 원하는 텍스트 추출 방식
    # infer_texts = [f["inferText"] for f in result["images"][0]["fields"]]
    # return "\n".join(infer_texts)

    # 이 위까지의 주석 코드가 실제 코드 아래는 테스트를 위한 가짜 코드============================
    print(f"⚠️ [TEST MODE] OCR 호출 생략됨. 파일 경로: {image_path}")

    # === 가짜 결과 반환 ===
    return "이것은 테스트용 OCR 결과입니다."


