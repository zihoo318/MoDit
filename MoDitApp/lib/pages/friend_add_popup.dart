import 'dart:ui';
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

    final userSnapshot = await db.child('user').child(friendId).get();
    if (!userSnapshot.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: const Text(
            "등록되지 않은 사용자입니다.",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFEAEAFF),
        ),
      );
      return;
    }

    await db.child('user').child(currentUserId).child('friends').child(friendId).set(true);
    await db.child('user').child(friendId).child('friends').child(currentUserId).set(true);

    Navigator.pop(context); // 팝업 닫기
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
              maxHeight: 320, // ✅ 세로 길이 제한
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '📧 친구 추가',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D0A64)),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1, color: Color(0xFF0D0A64)),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('추가할 친구의 이메일을 입력하세요',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFD3D3E2), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'friend@example.com',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: saveFriend,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D0A64),
                        side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
