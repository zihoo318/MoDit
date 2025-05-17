# 앱 실행의 진입점
from flask import Flask
from routes.stt_route import stt_bp
from routes.ocr_route import ocr_bp
from routes.summary_route import summary_bp
from routes.task_route import task_bp

from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)


# 블루프린트 등록
app.register_blueprint(stt_bp)
app.register_blueprint(ocr_bp)
app.register_blueprint(summary_bp)
app.register_blueprint(task_bp)
app.register_blueprint(note_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
