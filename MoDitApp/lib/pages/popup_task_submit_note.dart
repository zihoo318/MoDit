import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

Future<List<Map<String, dynamic>>> fetchUserNotes(String email) async {
  final userKey = email.replaceAll('.', '_');
  final db = FirebaseDatabase.instance.ref();
  final snapshot = await db.child('notes').child(userKey).get();

  if (!snapshot.exists) return [];

  final Map<String, dynamic> notesMap = Map<String, dynamic>.from(snapshot.value as Map);
  return notesMap.entries.map((entry) {
    final noteData = Map<String, dynamic>.from(entry.value);
    return {
      'noteId': entry.key,
      'title': noteData['title'],
      'imageUrl': noteData['imageUrl'],
    };
  }).toList();
}

Future<bool?> showNoteSubmitPopup({
  required BuildContext context,
  required String userEmail,
  required String taskId,
  required String subId,
  required String groupId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF9F9FD),
        child: Container(
          width: 700,
          height: 580,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📓 모딧 노트 제출',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D0A64))),
              const SizedBox(height: 12),
              const Divider(thickness: 1, color: Color(0xFF0D0A64)),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchUserNotes(userEmail),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final notes = snapshot.data!;
                    if (notes.isEmpty) return const Center(child: Text("저장된 노트가 없습니다."));

                    return Scrollbar(
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 4 / 3,
                        children: notes.map((note) {
                          return GestureDetector(
                            onTap: () async {
                              final sanitizedEmail = userEmail.replaceAll('.', '_');
                              try {
                                await FirebaseDatabase.instance
                                    .ref('tasks/$groupId/$taskId/subTasks/$subId/submissions/$sanitizedEmail')
                                    .set({
                                  'fileUrl': note['imageUrl'],
                                  'fileType': 'image',
                                  'submittedAt': DateTime.now().toIso8601String(),
                                });
                                Navigator.pop(context, true); // 성공
                              } catch (e) {
                                Navigator.pop(context, false); // 실패
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFD3D3E2), width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Image.network(
                                        note['imageUrl'],
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                      child: Text(
                                        note['title'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0D0A64),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context), // 아무 값도 안 넘김 (null 반환)
                  child: const Text("닫기"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
