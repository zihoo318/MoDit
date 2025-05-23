import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home.dart';
import 'login.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final db = FirebaseDatabase.instance.ref();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController name = TextEditingController();

  // 비밀번호 확인 상태 변수 추가
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;


  void registerUser() {
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다')),
      );
      return;
    }

    final userData = {
      'email': email.text,
      'password': password.text,
      'name': name.text,
    };

    db.child('user').child(email.text.replaceAll('.', '_')).set(userData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 완료')),
      );
      Navigator.pop(context); // 뒤로가기 = Home으로
    });
  }

  // ...생략된 import와 class 정의...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover, alignment: Alignment.topLeft), // ✅ 변경
          ),
          Positioned(
            left: 30,
            bottom: 30,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              child: Container(
                width: 750,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    _buildField('이메일', 'ex) abc@gmail.com', false, email),
                    const SizedBox(height: 20),
                    _buildField('비밀번호', '영문, 숫자 포함 8~16자', true, password),
                    const SizedBox(height: 20),
                    _buildField('비밀번호 확인', '비밀번호를 한번 더 입력해주세요.', true, confirmPassword),
                    const SizedBox(height: 20),
                    _buildField('이름', 'ex) 홍길동', false, name),
                    const SizedBox(height: 40),
                    _buildRoundedButton(context, '회원가입', registerUser),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildField(String label, String hint, bool obscure, TextEditingController controller) {
    bool isPassword = controller == password;
    bool isConfirm = controller == confirmPassword;

    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF404040),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscure
                ? isPassword
                ? !_isPasswordVisible
                : !_isConfirmPasswordVisible
                : false,
            cursorColor: Colors.black26, // ✅ 커서 색 변경
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder( // ✅ 비활성 테두리
                borderSide: BorderSide(color: Colors.black26),
              ),
              focusedBorder: OutlineInputBorder( // ✅ 포커스 테두리
                borderSide: BorderSide(color: Colors.black26, width: 2.0),
              ),
              suffixIcon: obscure
                  ? IconButton(
                icon: Icon(
                  (isPassword
                      ? _isPasswordVisible
                      : _isConfirmPasswordVisible)
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.black38,
                ),
                onPressed: () {
                  setState(() {
                    if (isPassword) {
                      _isPasswordVisible = !_isPasswordVisible;
                    } else {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    }
                  });
                },
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildRoundedButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: 360,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB8BDF1).withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0, // ✅ 그림자 제거
          shadowColor: Colors.transparent, // ✅ 번짐 방지
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF404040),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

}
