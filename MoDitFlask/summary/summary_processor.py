# summary/summary_processor.py

import requests
import os
import uuid
from config import config_env
from utils.file_handler import upload_to_object_storage

import openai
openai.api_key = config_env.OPENAI_API_KEY

def summarize_from_ncp(file_url, group_name):
    # 1. 파일 다운로드
    response = requests.get(file_url)
    if response.status_code != 200:
        raise Exception("파일 다운로드 실패")

    content = response.text.strip()
    if not content:
        raise Exception("빈 파일입니다")

    # 2. GPT 요약 요청
    summary_text = request_summary_from_gpt(content)
    print("gpt 요약 결과 : ",summary_text)

    # 3. 요약 결과 저장
    base_filename = str(uuid.uuid4())
    grouped_filename = f"{group_name}_{base_filename}.txt"
    with open(grouped_filename, 'w', encoding='utf-8') as f:
        f.write(summary_text)

    # 4. NCP Object Storage 업로드
    object_key = f"summary/{grouped_filename}"
    text_url = upload_to_object_storage(grouped_filename, object_key)
    os.remove(grouped_filename)

    return {
        "summary_url": text_url,
        "summary_preview": summary_text[:100]
    }

    # # 이 위까지의 코드가 실제 코드 아래는 테스트용 가짜 코드===================================
    # print(f"[TEST MODE] gpt 호출 생략됨.")

    # # === 가짜 결과 반환 ===
    # return "이것은 테스트용 gpt 결과입니다."

def request_summary_from_gpt(text):
    prompt = f"다음 텍스트를 한국어로 간결하게 요약해줘:\n\n{text[:3000]}"  # max tokens 방지 위해 길이 제한
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",  # 또는 gpt-4
        messages=[
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
    )
    return response['choices'][0]['message']['content'].strip()
