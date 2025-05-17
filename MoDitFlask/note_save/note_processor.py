import re
from utils.file_handler import save_temp_file, upload_to_object_storage, delete_file

def handle_note_upload(file, user_email, note_title):
    filename = custom_filename(file.filename)

    # 임시 파일 저장
    temp_path = save_temp_file(file, filename)

    # NCP Object Storage 저장 경로 (note로 시작)
    object_key = f"note/{user_email}/{note_title}/{filename}"

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
