from flask import Blueprint, request, jsonify
from ocr.ocr_processor import run_ocr
from utils.file_handler import save_temp_file, delete_file
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
        # delete_file(temp_path)  # ⬅️ 필요시 파일 삭제 (주석 처리)
        pass
