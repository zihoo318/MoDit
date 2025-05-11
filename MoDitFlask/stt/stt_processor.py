# stt/stt_processor.py
import requests, json, uuid, time, os
from config import config_env
from utils.file_handler import upload_to_object_storage

def process_stt(file_path, base_filename, group_name):
    # 파일명에 그룹명 포함
    grouped_filename = f"{group_name}_{base_filename}"

    # 오브젝트스토리지에 음성 파일 저장
    audio_key = f"stt_audio/{grouped_filename}.m4a"
    audio_url = upload_to_object_storage(file_path, audio_key)

    # STT 요청
    stt_result = request_stt(audio_url, completion='sync')

    # 결과를 txt로 저장 후 다시 업로드
    stt_text = stt_result.get("text", "")
    text_filename = f"{grouped_filename}.txt"
    with open(text_filename, 'w', encoding='utf-8') as f:
        f.write(stt_text)

    text_key = f"stt_transcript/{text_filename}"
    text_url = upload_to_object_storage(text_filename, text_key)
    os.remove(text_filename)

    return {
        "audio_url": audio_url,
        "text_url": text_url,
        "text_preview": stt_text[:100]
    }
    
    # # 이 위까지의 코드가 실제 코드 아래는 테스트용 가짜 코드===================================
    # print(f"⚠️ [TEST MODE] stt 호출 생략됨.")

    # # === 가짜 결과 반환 ===
    # return "이것은 테스트용 stt 결과입니다."


def request_stt(audio_path, completion, callback=None, userdata=None, forbiddens=None, boostings=None, wordAlignment=True, fullText=True, diarization=None, sed=None):
    api_url = 'https://clovaspeech-gw.ncloud.com/external/v1/11275/bc1e456a3d83549cc3304e90d597a845e543f4ddad32c9fd60bfddbec28c1544/recognizer/url'

    headers = {
        'Accept': 'application/json;UTF-8',
        'Content-Type': 'application/json;UTF-8',
        "X-CLOVASPEECH-API-KEY": config_env.NAVER_STT_SECRET_KEY
    }

    request_body = {
        'url': audio_path,
        'language': 'ko-KR',
        'completion': completion,
        'callback': callback,
        'userdata': userdata,
        'wordAlignment': wordAlignment,
        'fullText': fullText,
        'forbiddens': forbiddens,
        'boostings': boostings,
        'diarization': diarization,
        'sed': sed,
    }

    response = requests.post(headers=headers, url=api_url, data=json.dumps(request_body).encode('UTF-8'))

    try:
        data = response.json()
    except Exception as e:
        print("❌ 응답 파싱 오류:", e)
        print("📦 원본 응답:", response.text)
        return {"text": ""}

    #print("✅ Clova 응답:", json.dumps(data, indent=2, ensure_ascii=False))

    segments = data.get("segments", [])
    # text만 추출해서 이어붙이기
    joined_text = " ".join(seg["text"] for seg in segments if "text" in seg)

    print("응답에서 text만 추출 : ",joined_text)
    return {"text": joined_text}


