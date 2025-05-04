import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background2.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Container(
              width: 700,
              height: 500,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEDFF),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 300,
                    height: 70,
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: const Color(0x996495ED),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: const Center(
                      child: Text(
                        "로그인",
                        style: TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _buildTextField("아이디", "예: abc@gmail.com"),
                  _buildPasswordField("비밀번호", false),
                  _buildPasswordField("비밀번호 확인", true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF404040),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 500,
            child: TextField(
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

  Widget _buildPasswordField(String label, bool isConfirm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF404040),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 500,
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: isConfirm
                    ? "비밀번호를 한번 더 입력해주세요."
                    : "영문, 숫자 조합 8~16자",
                fillColor: Colors.white,
                filled: true,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.visibility_off),
              ),
            ),
          ),
        ],
      ),
    );
  }
}