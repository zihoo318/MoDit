from flask import Blueprint, request, jsonify
from routes.firebase_push import send_push_notification  # ✅ 이렇게!

push_bp = Blueprint('push', __name__)

@push_bp.route('/send_push', methods=['POST'])
def send_push():
    data = request.json
    token = data.get('token')
    title = data.get('title')
    body = data.get('body')

    if not all([token, title, body]):
        return jsonify({'success': False, 'message': '필수 값 누락'}), 400

    success = send_push_notification(token, title, body)
    return jsonify({'success': success}), 200 if success else 500