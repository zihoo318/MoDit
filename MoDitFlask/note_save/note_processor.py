import re
from utils.file_handler import (
    save_temp_file, upload_to_object_storage, delete_file,
    delete_all_files_in_prefix
)

def handle_note_upload(file, user_email, note_title):
    filename = custom_filename(file.filename)
    print(f"DEBUG: user_email={user_email}, note_title={note_title}, filename={filename}")

    # S3 key prefix
    prefix = f"note/{user_email}/{note_title}/"

    # 기존 파일 삭제
    delete_all_files_in_prefix(prefix)

    # 새 파일 저장
    temp_path = save_temp_file(file, filename)
    object_key = f"{prefix}{filename}"

    try:
        file_url = upload_to_object_storage(temp_path, object_key)
        return {
            "message": "Note upload successful",
            "file_url": file_url,
            "object_key": object_key
        }
    finally:
        delete_file(temp_path)

def custom_filename(filename):
    return re.sub(r'[^\w가-힣_.]', '_', filename)
