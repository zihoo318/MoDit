import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FriendAddPopup extends StatefulWidget {
  final String currentUserEmail;

  const FriendAddPopup({required this.currentUserEmail, super.key});

  @override
  State<FriendAddPopup> createState() => _FriendAddPopupState();
}

class _FriendAddPopupState extends State<FriendAddPopup> {
  final TextEditingController emailController = TextEditingController();
  final db = FirebaseDatabase.instance.ref();

  void saveFriend() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    final friendId = email.replaceAll('.', '_');
    final currentUserId = widget.currentUserEmail.replaceAll('.', '_');

    // ✅ 1. 존재하는 유저인지 확인
    final userSnapshot = await db.child('user').child(friendId).get();
    if (!userSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('존재하지 않는 사용자입니다')),
      );
      return;
    }

    // ✅ 2. 양방향 저장
    await db
        .child('user')
        .child(currentUserId)
        .child('friends')
        .child(friendId)
        .set(true);

    await db
        .child('user')
        .child(friendId)
        .child('friends')
        .child(currentUserId)
        .set(true);

    Navigator.pop(context); // 팝업 닫기
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
      backgroundColor: const Color(0xFFECE6F0),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('추가할 친구의 이메일을 입력하세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveFriend,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('저장', style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }
}
