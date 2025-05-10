# stt/stt_processor.py
import requests, json, uuid, time, os
from config import config_env
from utils.file_handler import upload_to_object_storage

def process_stt(file_path, base_filename, group_name):
    # # 파일명에 그룹명 포함
    # grouped_filename = f"{group_name}_{base_filename}"

    # # 오브젝트스토리지에 음성 파일 저장
    # audio_key = f"stt_audio/{grouped_filename}.m4a"
    # audio_url = upload_to_object_storage(file_path, audio_key)

    # # STT 요청
    # stt_result = request_stt(audio_url)

    # # 결과를 txt로 저장 후 다시 업로드
    # stt_text = stt_result.get("text", "")
    # text_filename = f"{grouped_filename}.txt"
    # with open(text_filename, 'w', encoding='utf-8') as f:
    #     f.write(stt_text)

    # text_key = f"stt_transcript/{text_filename}"
    # text_url = upload_to_object_storage(text_filename, text_key)
    # os.remove(text_filename)

    # return {
    #     "audio_url": audio_url,
    #     "text_url": text_url,
    #     "text_preview": stt_text[:100]
    # }
    
    # 이 위까지의 코드가 실제 코드 아래는 테스트용 가짜 코드===================================
    print(f"⚠️ [TEST MODE] stt 호출 생략됨.")

    # === 가짜 결과 반환 ===
    return "이것은 테스트용 stt 결과입니다."


def request_stt(audio_url):
    api_url = "https://clovaspeech-gw.ncloud.com/external/v1/recognizer/url"
    headers = {
        "Accept": "application/json;UTF-8",
        "X-CLOVASPEECH-API-KEY": config_env.NCLOUD_ACCESS_KEY,
        "Content-Type": "application/json"
    }

    body = {
        "language": "ko-KR",
        "url": audio_url,
        "completion": "sync"
    }

    res = requests.post(api_url, headers=headers, data=json.dumps(body))
    data = res.json()

    segments = data.get("segments", [])
    full_text = "\n".join([seg["text"] for seg in segments])
    return {"text": full_text}
