import firebase_admin
from firebase_admin import credentials, db


print("firebase_init.py 실행됨")  # ✅ 확인용

# 이미 초기화됐는지 확인
if not firebase_admin._apps:
    cred = credentials.Certificate("config/serviceAccountKey.json")
    firebase_admin.initialize_app(cred, {
        "databaseURL": "https://modit-a81ba-default-rtdb.firebaseio.com/"
    })
