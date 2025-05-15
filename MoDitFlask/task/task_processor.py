# task/task_processor.py

from werkzeug.utils import secure_filename
from utils.file_handler import save_temp_file, upload_to_object_storage, delete_file
import re

def handle_task_upload(file, group_id, user_email, task_title, subtask_title):
    filename = custom_filename(file.filename)

    # 임시 파일로 저장
    temp_path = save_temp_file(file, filename)

    # NCP Object Storage 경로 정의
    object_key = f"task/{group_id}/{user_email}/{task_title}_{subtask_title}/{filename}"

    try:
        # 업로드
        file_url = upload_to_object_storage(temp_path, object_key)
        return {
            "message": "Upload successful",
            "file_url": file_url,
            "object_key": object_key
        }
    finally:
        # 업로드 후 로컬 파일 삭제
        delete_file(temp_path)


def custom_filename(filename):
    # 한글/영어/숫자/공백/점만 허용 (공백은 _로)
    return re.sub(r'[^\w가-힣_.]', '_', filename)

