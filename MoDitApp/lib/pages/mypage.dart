import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart';

class MyPagePopup extends StatefulWidget {
  final String userEmail;
  final String userName;

  const MyPagePopup({
    required this.userEmail,
    required this.userName,
    Key? key,
  }) : super(key: key);

  @override
  State<MyPagePopup> createState() => _MyPagePopupState();
}

class _MyPagePopupState extends State<MyPagePopup> {
  late TextEditingController _nameController;
  final db = FirebaseDatabase.instance.ref();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final userKey = widget.userEmail.replaceAll('.', '_');
    await db.child('user').child(userKey).update({'name': newName});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: const Text(
          "이름이 수정되었습니다.",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFEAEAFF),
      ),
    );

    setState(() => _isEditingName = false);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFECE6F0),
            borderRadius: BorderRadius.circular(70),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '마이페이지',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/user_icon2.png'),
              ),
              const SizedBox(height: 10),

              _isEditingName
                  ? TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
                  : Text(
                _nameController.text,
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () {
                  if (_isEditingName) {
                    _updateName();
                  } else {
                    setState(() => _isEditingName = true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(_isEditingName ? '저장' : '이름 수정'),
              ),

              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
