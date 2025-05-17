from flask import Blueprint, request, jsonify
from note.note_processor import handle_note_upload

note_bp = Blueprint("note_route", __name__, url_prefix='/note')

@note_bp.route("/Note/upload", methods=["POST"])
def upload_note():
    if 'note' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['note']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    group_id = request.form.get('groupId')
    user_email = request.form.get('userEmail')
    note_title = request.form.get('noteTitle')

    if not all([group_id, user_email, note_title]):
        return jsonify({"error": "Missing required fields"}), 400

    result = handle_note_upload(file, group_id, user_email, note_title)
    return jsonify(result)
