import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'first_page.dart';
import 'home.dart';           // 뒤로가기 버튼용 홈
import 'first_page.dart';   // 로그인 성공 시 이동할 홈 화면

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final db = FirebaseDatabase.instance.ref();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  void loginUser() async {
    final userSnapshot = await db.child('user').child(email.text.replaceAll('.', '_')).get();

    if (userSnapshot.exists) {
      final data = userSnapshot.value as Map;
      if (data['password'] == password.text) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              currentUserEmail: email.text,
              currentUserName: data['name'], // DB에서 가져온 값
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_logo.png',
              fit: BoxFit.cover,
              alignment: Alignment.topLeft,
            ),
          ),
          // 왼쪽 아래 뒤로가기
          Positioned(
            left: 30,
            bottom: 30,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
              ),
            ),
          ),
          // 로그인 카드
          Center(
            child: Container(
              width: 650,
              padding: const EdgeInsets.symmetric(vertical: 110, horizontal: 60),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField('아이디', 'ex) abc@gmail.com', false, email),
                  const SizedBox(height: 20),
                  _buildField('비밀번호', '영문, 숫자 포함 8~16자', true, password),
                  const SizedBox(height: 40),
                  _buildRoundedButton(context, '로그인', loginUser),
                ],
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
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              suffixIcon: obscure ? const Icon(Icons.visibility_off) : null,
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
