# 임시로 파일을 다운 받는 경우 저장 및 삭제를 도움
import os
import boto3
from config import config_env

TEMP_DIR = "temp_files"  # 임시 디렉토리 (원하는 경로로 지정 가능)

# 임시 파일 저장 함수
def save_temp_file(file, filename): # 클라이언트로부터 받은 파일을 서버의 임시 디렉토리에 저장함
    os.makedirs(TEMP_DIR, exist_ok=True)
    path = os.path.join(TEMP_DIR, filename)
    file.save(path)
    return path

# 임시 파일 삭제 함수
def delete_file(path): # 저장한 임시 파일을 나중에 삭제하여 공간 낭비 방지
    if os.path.exists(path):
        os.remove(path)

# object storage에 파일 업로드
def upload_to_object_storage(local_path, key):
    s3 = boto3.client(
        's3',
        aws_access_key_id=config_env.NCLOUD_ACCESS_KEY,
        aws_secret_access_key=config_env.NCLOUD_SECRET_KEY,
        endpoint_url=config_env.NCLOUD_ENDPOINT
    )

    # 파일 확장자에 따라 ContentType 자동 지정 (기본은 binary)
    content_type = "application/octet-stream"
    if key.endswith(".txt"):
        content_type = "text/plain; charset=utf-8"
    elif key.endswith(".m4a"):
        content_type = "audio/mp4"

    s3.upload_file(
        local_path,
        config_env.NCLOUD_BUCKET_NAME,
        key,
        ExtraArgs={
            "ContentType": content_type,
            "ACL": "public-read"
        }
    )

    return f"{config_env.NCLOUD_ENDPOINT}/{config_env.NCLOUD_BUCKET_NAME}/{key}"

