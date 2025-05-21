# routes/stt_route.py
from flask import Blueprint, request, jsonify
from utils.file_handler import save_temp_file, delete_file, delete_object_by_url
from stt.stt_processor import process_stt
import uuid
import traceback

stt_bp = Blueprint('stt', __name__, url_prefix='/stt')

@stt_bp.route('/upload', methods=['POST'])
def upload_voice_file():
    if 'voice' not in request.files:
        return jsonify({'error': 'No voice file provided'}), 400

    group_name = request.form.get('groupId')
    if not group_name:
        return jsonify({'error': 'No groupId provided'}), 400

    file = request.files['voice']
    filename_base = str(uuid.uuid4())
    temp_filename = f"{filename_base}.m4a"
    temp_path = save_temp_file(file, temp_filename)

    print("[DEBUG] 요청 수신됨")
    print("FILES:", request.files)
    print("FORM:", request.form)

    ##
    if 'voice' not in request.files:
        return jsonify({'error': 'No voice file provided'}), 400

    group_name = request.form.get('groupId') 
    if not group_name:
        return jsonify({'error': 'No groupId provided'}), 400
    ##

    try:
        result = process_stt(temp_path, filename_base, group_name)  # group_name 전달

        return jsonify(result), 200

    except Exception as e:
        print("STT 처리 중 에러 발생:")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

    finally:
        delete_file(temp_path)

# 음성녹음파일. 텍스트화파일,요약본 한번에 삭제 함수
@stt_bp.route('/delete_audio_text', methods=['POST'])
def delete_audio_and_text():
    try:
        data = request.get_json()
        audio_url = data.get('audio_url')
        text_url = data.get('text_url')
        summary_url = data.get('summary_url')

        if not audio_url or not text_url:
            return jsonify({'error': 'Missing audio_url or text_url'}), 400

        delete_object_by_url(audio_url)
        delete_object_by_url(text_url)
        if summary_url:
            delete_object_by_url(summary_url)

        return jsonify({'result': 'success'}), 200

    except Exception as e:
        print("파일 삭제 중 에러 발생:")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500