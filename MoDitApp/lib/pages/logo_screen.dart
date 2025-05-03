import 'package:flutter/material.dart';

class LogoScreen extends StatelessWidget {
  const LogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경 흰색
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지 (logo.png 또는 logo_img.png 중 하나)
            Image.asset(
              'assets/logo.png', // 또는 'assets/logo_img.png'
              width: 100, // 필요시 크기 조절
            ),
            const SizedBox(height: 16),
            const Text(
              'MoDit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8EBEFF), // 이미지와 유사한 연한 파란색
              ),
            ),
          ],
        ),
      ),
    );
  }
}
