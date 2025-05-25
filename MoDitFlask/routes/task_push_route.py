from config.firebase_init import *  # Firebase 초기화
from firebase_admin import db
from utils.send_fcm import send_fcm_notification
from flask import Blueprint, request, jsonify

task_push_bp = Blueprint('task_push', __name__)

@task_push_bp.route('/send_task_alert', methods=['POST'])
def send_task_alert():
    data = request.json
    group_id = data.get("groupId")
    title = data.get("title")
    sender_email = data.get("senderEmail")  # 등록자 이메일
    print("sender_email:", repr(sender_email))

    if not group_id or not title or not sender_email:
        return jsonify({"error": "Missing data"}), 400
    
    # 이메일 포맷 변환: Firebase 키와 동일하게
    sanitized_sender = (
        sender_email.replace('.', '_')
                    .replace('#', '_')
                    .replace('$', '_')
                    .replace('[', '_')
                    .replace(']', '_')
                    .replace('/', '_')
    )

    group_ref = db.reference(f"groupStudies/{group_id}")
    members = group_ref.child("members").get()
    group_name = group_ref.child("name").get()

    if not members or not group_name:
        return jsonify({"error": "Invalid group"}), 400

    for email_key in members:
        email_key_str = str(email_key)
        print("비교 중:", email_key_str, sanitized_sender)
        if email_key_str == sanitized_sender:
            print("등록자 본인 → 알림 건너뜀")
            continue  # 등록자 본인은 제외
        user_ref = db.reference(f"user/{email_key}")
        fcm_token = user_ref.child("fcmToken").get()
        if fcm_token:
            send_fcm_notification(
                fcm_token,
                "📘 새로운 과제 알림",
                f"[{group_name}]에 새로운 과제가 등록되었습니다. ({title})"
            )

    return jsonify({"status": "과제 알림 전송 완료"}), 200

