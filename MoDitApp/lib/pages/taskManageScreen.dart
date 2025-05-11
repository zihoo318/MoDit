import 'package:flutter/material.dart';

class TaskManageScreen extends StatefulWidget {
  const TaskManageScreen({Key? key}) : super(key: key);

  @override
  _TaskManageScreenState createState() => _TaskManageScreenState();
}

class _TaskManageScreenState extends State<TaskManageScreen> {
  int _selectedIndex = 0; // 0: 과제 관리, 1: 과제 확인
  late PageController _pageController; // PageController로 슬라이드 관리

  // 각 화면에 표시될 내용
  final List<Widget> _screens = [
    Center(child: Text('과제 관리 화면', style: TextStyle(fontSize: 24))),
    Center(child: Text('과제 확인 화면', style: TextStyle(fontSize: 24))),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex); // 초기 페이지 설정
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 원형 버튼 두 개로 탭 전환
          Padding(
            padding: const EdgeInsets.only(top: 50.0), // 버튼 위치 위로 올리기
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0; // 과제 관리 화면으로 변경
                    });
                    _pageController.animateToPage(
                      _selectedIndex,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 50, // 원형 버튼 크기 줄이기
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                    ),
                    child: Icon(
                      Icons.assignment,
                      color: Colors.white,
                      size: 25, // 아이콘 크기 줄이기
                    ),
                  ),
                ),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1; // 과제 확인 화면으로 변경
                    });
                    _pageController.animateToPage(
                      _selectedIndex,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 50, // 원형 버튼 크기 줄이기
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 25, // 아이콘 크기 줄이기
                    ),
                  ),
                ),
              ],
            ),
          ),
          // PageView로 슬라이드 전환
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index; // 슬라이드로 이동할 때 index 업데이트
                });
              },
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
