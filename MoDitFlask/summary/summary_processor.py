# summary/summary_processor.py

import requests
import os
import uuid
from utils.file_handler import upload_to_object_storage
from config import config_env
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
    summary_text = request_summary_from_voice(content)
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

def request_summary_from_note(text):
    prompt = f"""
다음 텍스트를 핵심 단어 위주로 정리해 요약해줘. 요약할 때는 다음과 같은 규칙을 지켜줘:

1. 핵심 문장/단락을 파악하고 글의 의도를 유지하면서 요약해야해.
2. 각 항목은 상황에 따라 번호(1, 2, 3, ...) 또는 글머리 기호(-)로 나눠서 작성해.
3. 문장은 짧고 간결하게 써.
4. 영어 문장은 인용하듯 그대로 유지하거나 핵심 단어만 인용해.
5. 너무 긴 영어 문장은 핵심 단어로 줄이거나 한글로 의미를 요약해도 돼.

지금부터 아래 텍스트를 위 지침에 따라 깔끔하게 요약해줘:

{text[:3000]}
"""

    response = openai.ChatCompletion.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.5,
    )
    return response['choices'][0]['message']['content'].strip()


def request_summary_from_voice(text):
    prompt = f"""다음은 회의 녹취 내용을 텍스트로 변환한 것입니다. 회의 요점만 정리해서 한국어로 간결하게 요약해줘:\n\n{text[:3000]}"""

    response = openai.ChatCompletion.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.5,
    )
    return response['choices'][0]['message']['content'].strip()