import 'package:flutter/material.dart';
import 'homeworkManager.dart';

class HomeworkCheckScreen extends StatelessWidget {
  final String userName;

  const HomeworkCheckScreen({super.key, required this.userName});

  Color _getUserColor(String name) {
    switch (name) {
      case '가을':
        return const Color(0xFF4C92D7);
      case '윤지':
        return const Color(0xFF6495ED);
      case '유진':
        return const Color(0xFF7DB5EB);
      case '지후':
        return const Color(0xFF7DB5EB);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경
          Positioned.fill(
            child: Image.asset('assets/images/background1.png', fit: BoxFit.cover),
          ),
          // 유저 아이콘
          Positioned(
            top: 20,
            right: 20,
            child: Image.asset('assets/images/user_icon.png', width: 100),
          ),
          // 본문
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 뒤로가기 버튼
                Align(
                  alignment: Alignment.topLeft,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeworkManagerScreen()),
                      );
                    },
                    child: const Text("뒤로가기"),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      // 왼쪽: 유저 리스트
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var name in ['가을', '윤지', '유진', '지후'])
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HomeworkCheckScreen(userName: name),
                                  ),
                                );
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEDFF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getUserColor(name),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        name,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Row(
                                      children: [
                                        Icon(Icons.favorite, color: Colors.blue),
                                        SizedBox(width: 6),
                                        Text('어쩌고'),
                                      ],
                                    ),
                                    const Row(
                                      children: [
                                        Icon(Icons.favorite, color: Colors.blue),
                                        SizedBox(width: 6),
                                        Text('저쩌고'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // 오른쪽: 선택된 유저 과제 내용
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEDFF),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getUserColor(userName),
                                ),
                                alignment: Alignment.center,
                                child: Text(userName, style: const TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(height: 20),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    '제출한 파일 없음',
                                    style: TextStyle(color: Colors.grey, fontSize: 18),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
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
