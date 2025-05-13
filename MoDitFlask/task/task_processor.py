# task/task_processor.py

from werkzeug.utils import secure_filename
from utils.file_handler import save_temp_file, upload_to_object_storage, delete_file

def handle_task_upload(file, group_id, user_email, task_title, subtask_title):
    filename = secure_filename(file.filename)

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
