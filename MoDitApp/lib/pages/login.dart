import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'first_page.dart';
import 'home.dart';
import 'first_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'join.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final db = FirebaseDatabase.instance.ref();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool _isPasswordVisible = false;

  void loginUser() async {
    final userSnapshot = await db.child('user').child(email.text.replaceAll('.', '_')).get();

    if (userSnapshot.exists) {
      final data = Map<String, dynamic>.from(userSnapshot.value as Map);
      if (data['password'] == password.text) {
        final userKey = email.text.replaceAll('.', '_');
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await db.child('user').child(userKey).update({'fcmToken': token});
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              currentUserEmail: email.text,
              currentUserName: data['name'],
            ),
          ),
        );
      } else {
        _showError('비밀번호가 일치하지 않습니다');
      }
    } else {
      _showError('등록되지 않은 사용자입니다');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFEAEAFF),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ✅ 배경 이미지 변경
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topLeft,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 30),
              child: Container(
                width: 650,
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 60),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ 상단 로고 삽입
                    Image.asset('assets/images/logo.png', width: 200, height: 160, fit: BoxFit.contain),
                    const SizedBox(height: 20),
                    _buildField('이메일', 'ex) abc@gmail.com', false, email),
                    const SizedBox(height: 20),
                    _buildField('비밀번호', '영문, 숫자 포함 8~16자', true, password),
                    const SizedBox(height: 40),
                    _buildRoundedButton(context, '로그인', loginUser),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const JoinScreen()),
                        );
                      },
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Color(0xFF404040),
                          fontSize: 16,
                        ),
                      ),
                    ),
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
            obscureText: obscure ? !_isPasswordVisible : false,
            cursorColor: Colors.black26,   // 커서 색상
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(  // 포커스 시 테두리 색
                borderSide: BorderSide(color: Colors.black26, width: 2.0), // 포커스 시 테두리 색
                borderRadius: BorderRadius.circular(4),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              suffixIcon: obscure
                  ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
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
          elevation: 0,
          shadowColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
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