# 임시로 파일을 다운 받는 경우 저장 및 삭제를 도움
import os

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
