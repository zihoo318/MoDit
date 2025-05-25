from flask import Blueprint, request, jsonify
from ocr.ocr_processor import run_ocr
from utils.file_handler import save_temp_file, delete_file
from summary.summary_processor import request_summary_from_note  # 요약 함수
import uuid
import traceback

ocr_bp = Blueprint('ocr', __name__, url_prefix='/ocr')

@ocr_bp.route('/upload', methods=['POST'])
def upload_ocr_image():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']
    filename_base = str(uuid.uuid4())
    temp_filename = f"{filename_base}.jpg"
    temp_path = save_temp_file(file, temp_filename)

    try:
        # ✅ OCR 처리만 하고 바로 리턴
        extracted_text = run_ocr(temp_path)

        return jsonify({
            'text': extracted_text
        }), 200

    except Exception as e:
        print("❌ OCR 처리 중 에러 발생:")
        traceback.print_exc()  # ⬅️ 콘솔에 에러 메시지 출력
        return jsonify({'error': str(e)}), 500

    finally:
        delete_file(temp_path)  # ⬅️ 필요시 파일 삭제 (주석 처리)


# 노트 전체 요약 함수
@ocr_bp.route('/upload_and_summarize_text', methods=['POST'])
def upload_and_summarize_text():
    if 'image' not in request.files not in request.form:
        return jsonify({'error': '이미지가 누락되었습니다.'}), 400

    file = request.files['image']
    filename_base = str(uuid.uuid4())
    temp_filename = f"{filename_base}.jpg"
    temp_path = save_temp_file(file, temp_filename)

    try:
        # OCR 처리
        extracted_text = run_ocr(temp_path)

        # 요약 처리 (GPT API 호출)
        summary_text = request_summary_from_note(extracted_text)

        return jsonify({
            "summary": summary_text
        }), 200

    except Exception as e:
        print("요약 처리 중 에러 발생:")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

    finally:
        delete_file(temp_path)