from flask import Blueprint, request, jsonify
from note_save.note_processor import handle_note_upload
from utils.file_handler import delete_note_from_object_storage

note_bp = Blueprint("note_route", __name__, url_prefix='/note')

@note_bp.route("/upload", methods=["POST"])
def upload_note():
    if 'note' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['note']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    user_email = request.form.get('userEmail')
    note_title = request.form.get('noteTitle')

    if not all([user_email, note_title]):
        return jsonify({"error": "Missing required fields"}), 400

    result = handle_note_upload(file, user_email, note_title)
    return jsonify(result)

@note_bp.route('/delete_note', methods=['POST'])
def delete_note():
    try:
        data = request.get_json()
        user_email = data['email']
        note_title = data['title']
        delete_note_from_object_storage(user_email, note_title)
        return jsonify({'success': True})
    except Exception as e:
        print(f"ERROR: {e}")
        return jsonify({'error': str(e)}), 500