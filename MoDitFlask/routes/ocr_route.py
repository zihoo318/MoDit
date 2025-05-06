# 예시 코드

from flask import Blueprint, request, jsonify
from ocr.ocr_processor import run_ocr
from firebase.firebase_config import upload_to_firebase
from utils.file_handler import save_temp_file, delete_file

import uuid

ocr_bp = Blueprint('ocr', __name__, url_prefix='/ocr')

@ocr_bp.route('/upload', methods=['POST'])
def upload_ocr_image():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']
    temp_filename = f"{uuid.uuid4()}.jpg"q
    temp_path = save_temp_file(file, temp_filename)

    try:
        # OCR 실행
        extracted_text = run_ocr(temp_path)

        # Firebase Storage에 결과 저장
        result_path = f"ocr_results/{temp_filename}.txt"
        upload_to_firebase(result_path, extracted_text)

        return jsonify({'text': extracted_text, 'firebase_path': result_path}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

    finally:
        delete_file(temp_path)
