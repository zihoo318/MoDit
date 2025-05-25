# routes/summary_route.py

from flask import Blueprint, request, jsonify
from summary.summary_processor import summarize_from_ncp
import traceback

summary_bp = Blueprint('summary', __name__, url_prefix='/summary')

@summary_bp.route('/generate', methods=['POST'])
def generate_summary():
    try:
        data = request.get_json()
        file_url = data.get('fileUrl')
        group_name = data.get('groupName')

        if not file_url or not group_name:
            return jsonify({'error': 'Missing fileUrl or groupName'}), 400

        result = summarize_from_ncp(file_url, group_name)

        if result["summary_text"] is None:
            return jsonify({'message': '요약할 내용이 없습니다.', 'summary_text': ''}), 200

        return jsonify(result), 200

    except Exception as e:
        print("요약 처리 중 에러 발생:")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
