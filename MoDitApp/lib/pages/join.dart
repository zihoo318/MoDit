import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  void _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();
    final name = nameController.text.trim();

    if (password != confirm) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseReference ref = FirebaseDatabase.instance.ref("users/${user.uid}");
        await ref.set({
          "email": email,
          "name": name,
        });
      }

      _showMessage('회원가입 완료!');
      Navigator.pop(context); // 가입 후 이전 화면(로그인)으로 이동
    } catch (e) {
      _showMessage('에러: ${e.toString()}');
    }
  }

  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background2.png', fit: BoxFit.cover),
          ),
          Positioned(
            top: 30,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 40),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Center(
            child: Container(
              width: 700,
              height: 650,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEDFF),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("회원가입", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildTextField("이메일", "예: abc@gmail.com", emailController),
                  _buildPasswordField("비밀번호", passwordController),
                  _buildPasswordField("비밀번호 확인", confirmPasswordController),
                  _buildTextField("이름", "예: 홍길동", nameController),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0x996495ED),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: const Text("회원가입", style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          SizedBox(
            width: 500,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                fillColor: Colors.white,
                filled: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          SizedBox(
            width: 500,
            child: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "영문, 숫자 조합 8~16자",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.visibility_off),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
