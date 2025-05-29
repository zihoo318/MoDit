from config.firebase_init import *        # ✅ 반드시 최상단!
from firebase_admin import db
from utils.send_fcm import send_fcm_notification
from flask import Blueprint, request, jsonify


meeting_push_bp = Blueprint('meeting_push', __name__)

@meeting_push_bp.route('/send_meeting_alert', methods=['POST'])
def send_meeting_alert():
    data = request.json
    group_id = data.get("groupId")
    date = data.get("date")
    sender_email = data.get("senderEmail")  # 등록자 이메일

    if not group_id or not date or not sender_email:
        return jsonify({"error": "Missing data"}), 400

    # 이메일 키 변환 (Firebase DB와 동일한 포맷으로)
    sanitized_sender = (
        sender_email.replace('.', '_')
                    .replace('#', '_')
                    .replace('$', '_')
                    .replace('[', '_')
                    .replace(']', '_')
                    .replace('/', '_')
    )

    group_ref = db.reference(f"groupStudies/{group_id}")
    members_ref = group_ref.child("members").get()
    group_name = group_ref.child("name").get()

    if not members_ref or not group_name:
        return jsonify({"error": "Invalid group or members"}), 400

    for email_key in members_ref:
        if email_key == sanitized_sender:
            print("등록자 본인 → 알림 건너뜀")
            continue  # 등록자 본인 제외
        user_ref = db.reference(f"user/{email_key}")
        fcm_token = user_ref.child("fcmToken").get()
        if fcm_token:
            title = "📅 새로운 미팅 알림"
            body = f"[{group_name}]에 새로운 미팅이 등록되었습니다. ({date})"
            send_fcm_notification(fcm_token, title, body)

    return jsonify({"status": "알림 전송 완료"}), 200
