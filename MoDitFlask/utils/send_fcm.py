import firebase_admin
from firebase_admin import messaging

def send_fcm_notification(token, title, body):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        token=token,
    )

    try:
        response = messaging.send(message)
        print('✅ 메시지 전송 성공:', response)
        return True
    except Exception as e:
        print('❌ 메시지 전송 실패:', e)
        return False
