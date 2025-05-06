from flask import Blueprint, request, jsonify
import boto3
from botocore.client import Config
import config  # 환경변수
import uuid
import requests
import json

stt_bp = Blueprint('stt', __name__, url_prefix='/stt')

# Naver Object Storage client
s3 = boto3.client(
    's3',
    aws_access_key_id=config.NCLOUD_ACCESS_KEY,
    aws_secret_access_key=config.NCLOUD_SECRET_KEY,
    endpoint_url=config.NCLOUD_ENDPOINT,
    config=Config(signature_version='s3v4')
)

@stt_bp.route('/upload', methods=['POST'])
def upload_and_request_stt():
    if 'audio' not in request.files:
        return jsonify({'error': '음성 파일이 필요합니다.'}), 400

    file = request.files['audio']
    file_id = str(uuid.uuid4())
    filename = f"stt_audio/{file_id}.mp3"

    # Object Storage에 업로드
    try:
        s3.upload_fileobj(
            file,
            config.NCLOUD_BUCKET_NAME,
            filename,
            ExtraArgs={'ContentType': 'audio/mpeg'}
        )
    except Exception as e:
        return jsonify({'error': f'S3 업로드 실패: {str(e)}'}), 500

    # Clova Speech API에 인식 요청
    clova_api_url = f"https://clovaspeech-gw.ncloud.com/external/v1/recognizer/{config.NCLOUD_SPEECH_DOMAIN}/recognize"

    headers = {
        "Accept": "application/json",
        "X-NCP-APIGW-API-KEY-ID": config.NCLOUD_CLIENT_ID,
        "X-NCP-APIGW-API-KEY": config.NCLOUD_CLIENT_SECRET,
        "Content-Type": "application/json"
    }

    payload = {
        "dataKey": filename,
        "language": "ko-KR",
        "completion": "async",  # 비동기 요청
        "callback": ""  # 콜백 URL이 없으면 결과는 Object Storage에 저장됨
    }

    try:
        response = requests.post(clova_api_url, headers=headers, data=json.dumps(payload))
        response.raise_for_status()
        return jsonify(response.json())
    except Exception as e:
        return jsonify({'error': f'Clova STT 요청 실패: {str(e)}'}), 500
