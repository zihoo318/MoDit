# 임시로 파일을 다운 받는 경우 저장 및 삭제를 도움
import os
import boto3
from config import config_env
from urllib.parse import quote


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
    elif key.endswith(".jpg"):
        content_type = "image/jpeg"
    print(f"DEBUG: bucket={config_env.NCLOUD_BUCKET_NAME}, key={key}")

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

def delete_note_from_object_storage(user_email, note_title):
    s3 = boto3.client(
        's3',
        aws_access_key_id=config_env.NCLOUD_ACCESS_KEY,
        aws_secret_access_key=config_env.NCLOUD_SECRET_KEY,
        endpoint_url=config_env.NCLOUD_ENDPOINT
    )

    prefix = f"note/{user_email}/{note_title}/"
    response = s3.list_objects_v2(
        Bucket=config_env.NCLOUD_BUCKET_NAME,
        Prefix=prefix
    )

    # 객체가 없을 경우
    if 'Contents' not in response:
        print(f"DEBUG: No objects found under {prefix}")
        return

    for obj in response['Contents']:
        print(f"DEBUG: Deleting {obj['Key']}")
        s3.delete_object(
            Bucket=config_env.NCLOUD_BUCKET_NAME,
            Key=obj['Key']
        )

def delete_all_files_in_prefix(prefix):
    s3 = boto3.client(
        's3',
        aws_access_key_id=config_env.NCLOUD_ACCESS_KEY,
        aws_secret_access_key=config_env.NCLOUD_SECRET_KEY,
        endpoint_url=config_env.NCLOUD_ENDPOINT
    )

    response = s3.list_objects_v2(Bucket=config_env.NCLOUD_BUCKET_NAME, Prefix=prefix)

    if 'Contents' in response:
        objects = [{'Key': obj['Key']} for obj in response['Contents']]
        s3.delete_objects(
            Bucket=config_env.NCLOUD_BUCKET_NAME,
            Delete={'Objects': objects}
        )
        print(f"🧹 {len(objects)}개 파일 삭제됨: {prefix}")