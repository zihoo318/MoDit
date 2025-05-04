import 'package:flutter/material.dart';

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
              'assets/images/background2.png',
              fit: BoxFit.cover,
            ),
          ),
          // 내용 구성
          Center(
            child: Container(
              width: 700,
              height: 400,
              padding: const EdgeInsets.symmetric(vertical: 50),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEDFF),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
                children: [
                  // 로그인 버튼
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 250,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0x996495ED),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        "로그인",
                        style: TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // 회원가입 버튼
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 250,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0x996495ED),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        "회원가입",
                        style: TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
