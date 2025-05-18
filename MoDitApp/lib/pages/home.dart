import 'package:flutter/material.dart';
import 'login.dart';   // 파일명이 login_screen.dart라고 가정
import 'join.dart';   // 파일명이 join_screen.dart라고 가정

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_logo.png',
              fit: BoxFit.cover,
              alignment: Alignment.topLeft,
            ),
          ),
          // 가운데 카드
          Center(
            child: Container(
              width: 600,
              padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRoundedButton(context, '로그인'),
                  const SizedBox(height: 60),
                  _buildRoundedButton(context, '회원가입'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedButton(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {
        if (text == '로그인') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else if (text == '회원가입') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JoinScreen()),
          );
        }
      },
      child: Container(
        width: 267,
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFFB8BDF1).withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF404040),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
