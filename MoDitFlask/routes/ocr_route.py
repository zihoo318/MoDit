# 예시 코드

from flask import Blueprint, request
from ocr.ocr_processor import run_ocr

ocr_bp = Blueprint('ocr', __name__, url_prefix='/ocr')

@ocr_bp.route('/upload', methods=['POST'])
def upload_image():
    image_file = request.files['image']
    text = run_ocr(image_file)
    return {'text': text}
