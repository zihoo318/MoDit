# routes/task_route.py

from flask import Blueprint, request, jsonify
from task.task_processor import handle_task_upload

task_route = Blueprint("task_route", __name__)

@task_route.route("/Task/upload", methods=["POST"])
def upload_task():
    if 'task' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['task']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    group_id = request.form.get('groupId')
    user_email = request.form.get('userEmail')
    task_title = request.form.get('taskTitle')
    subtask_title = request.form.get('subTaskTitle')

    if not all([group_id, user_email, task_title, subtask_title]):
        return jsonify({"error": "Missing required fields"}), 400

    result = handle_task_upload(file, group_id, user_email, task_title, subtask_title)
    return jsonify(result)
