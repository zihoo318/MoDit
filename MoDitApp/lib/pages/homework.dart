import 'package:flutter/material.dart';

class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/background1.png',
              fit: BoxFit.cover,
            ),
          ),
          // 오른쪽 상단 유저 아이콘
          Positioned(
            top: 20,
            right: 20,
            child: Image.asset(
              'assets/images/user_icon.png',
              width: 50,
            ),
          ),
          // 본문
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 책 아이콘
                Center(
                  child: Image.asset(
                    'assets/images/homework_icon.png',
                    width: 100, // 크기 키움
                  ),
                ),
                const SizedBox(height: 50),

                // 첫 번째 과제
                const Text(
                  "2025. 04. 25.",
                  style: TextStyle(fontSize: 30),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFDBEDFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "과제내용어쩌고\n1.~ ~\n2.~ ~",
                    style: TextStyle(fontSize: 30),
                  ),
                ),
                const SizedBox(height: 30),

                // 두 번째 과제 (내용 비어있음)
                const Text(
                  "2025. 04. 20.",
                  style: TextStyle(fontSize: 30),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Color(0xFFDBEDFF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
