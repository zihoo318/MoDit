from flask import Blueprint, request, jsonify
from ocr.ocr_processor import run_ocr
from utils.file_handler import save_temp_file, delete_file

import uuid
import boto3
from botocore.client import Config
import config  # 환경 변수 불러오는 파일

ocr_bp = Blueprint('ocr', __name__, url_prefix='/ocr')

# Naver Cloud Object Storage 클라이언트 설정
s3_client = boto3.client(
    's3',
    aws_access_key_id=config.NCLOUD_ACCESS_KEY,
    aws_secret_access_key=config.NCLOUD_SECRET_KEY,
    endpoint_url=config.NCLOUD_ENDPOINT,
    config=Config(signature_version='s3v4')
)

@ocr_bp.route('/upload', methods=['POST'])
def upload_ocr_image():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']
    filename_base = str(uuid.uuid4())
    temp_filename = f"{filename_base}.jpg"
    temp_path = save_temp_file(file, temp_filename)

    try:
        # 1. OCR 처리
        extracted_text = run_ocr(temp_path)

        # 2. 텍스트 업로드용 파일 생성
        result_filename = f"{filename_base}.txt"
        result_key = f"ocr_results/{result_filename}"

        # 3. 문자열을 바이너리로 변환해 Object Storage에 업로드
        s3_client.put_object(
            Bucket=config.NCLOUD_BUCKET_NAME,
            Key=result_key,
            Body=extracted_text.encode('utf-8'),
            ContentType='text/plain'
        )

        result_url = f"{config.NCLOUD_ENDPOINT}/{config.NCLOUD_BUCKET_NAME}/{result_key}"

        return jsonify({
            'text': extracted_text,
            'object_storage_path': result_key,
            'url': result_url
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

    finally:
        delete_file(temp_path)
