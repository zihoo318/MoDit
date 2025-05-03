import 'package:flutter/material.dart';

class StudyTimeScreen extends StatelessWidget {
  final List<Map<String, String>> studyData = [
    {'name': '가을', 'time': '3:25:45'},
    {'name': '문지', 'time': '5:43:23'},
    {'name': '유진', 'time': '1:38:10'},
    {'name': '지훈', 'time': '3:25:45'},
    {'name': '시연', 'time': '5:43:23'},
    {'name': '지연', 'time': '1:38:10'},
  ];

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
          // 콘텐츠
          SafeArea(
            child: Column(
              children: [
                // 상단바
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 20, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        '스터디 이름',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Image.asset(
                        'assets/images/studytime_icon.png',
                        width: 28,
                        height: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'MoDit',
                        style: TextStyle(
                          color: Color(0xFF6088D3),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Image.asset(
                        'assets/images/user_icon.png',
                        width: 28,
                        height: 28,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // 스터디 멤버 타일
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: GridView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: studyData.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = studyData[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFE9F0FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 이름
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF8BA9F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item['name']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Image.asset(
                                  'assets/images/study_icon.png',
                                  width: 40,
                                  height: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  item['time']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
