import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

Future<String?> uploadNoteToFirebaseStorage(File file, String email, String title) async {
  try {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final safeEmail = email.replaceAll('.', '_');

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('notes/$safeEmail/$title/$fileName');

    final uploadTask = await storageRef.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print('🔥 Firebase Storage 업로드 실패: $e');
    return null;
  }
}
