import boto3
from flask import Flask, request, jsonify
from botocore.client import Config

app = Flask(__name__)

# Naver Object Storage 설정
ACCESS_KEY = 'ncp_iam_BPAMKR1HDeJeuoAEAEF9'
SECRET_KEY = 'ncp_iam_BPKMKR2czZhbfOzyc5paRnjtmbx4aB2Tua'
ENDPOINT = 'https://kr.object.ncloudstorage.com'
BUCKET_NAME = 'modit-starage'

# S3 Client 생성 (Endpoint와 Signature 버전 지정 필수)
s3 = boto3.client(
    's3',
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    endpoint_url=ENDPOINT,
    config=Config(signature_version='s3v4')
)

@app.route('/upload', methods=['POST'])
def upload_file():
    file = request.files['file']
    file_name = file.filename

    try:
        s3.upload_fileobj(file, BUCKET_NAME, file_name)
        file_url = f"{ENDPOINT}/{BUCKET_NAME}/{file_name}"
        return jsonify({'message': '업로드 성공', 'url': file_url})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
