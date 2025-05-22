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
    print("gpt 요약 결과 : ", summary_text)

    # 3. 바로 반환 (파일 저장, 업로드 없이)
    return {
        "summary_text": summary_text,
    }


def request_summary_from_note(text):
    prompt = f"""
다음 텍스트를 핵심 단어 위주로 정리해 요약해줘. 요약할 때는 다음과 같은 규칙을 지켜줘:

1. 핵심 문장/단락을 파악하고 글의 의도를 유지하면서 요약해야해.
2. 각 항목은 상황에 따라 번호(1, 2, 3, ...) 또는 글머리 기호(-)로 나눠서 작성해.
3. 문장은 짧고 간결하게 써.
4. 예시가 나열되어 있다면 최대한 다 생략. 패턴을 분석해서 간략하게 설명.
5. 너무 긴 영어 문장은 핵심 단어로 줄이거나 한글로 의미를 요약해도 돼.
6. 요약본의 문장 수는 전체 텍스트의 문장 수의 1/3 정도로 줄어야해

지금부터 아래 텍스트를 위 지침에 따라 최대한 간결하고 깔끔하게 요약해줘:

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