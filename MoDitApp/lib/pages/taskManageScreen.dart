import 'package:flutter/material.dart';

class TaskManageScreen extends StatefulWidget {
  final int tabIndex;
  final Function(int) onTabChanged;

  const TaskManageScreen({required this.tabIndex, required this.onTabChanged, Key? key}) : super(key: key);

  @override
  _TaskManageScreenState createState() => _TaskManageScreenState();
}

class _TaskManageScreenState extends State<TaskManageScreen> {
  late PageController _pageController;
  int selectedTaskIndex = 0;
  final List<Map<String, dynamic>> tasks = [
    {
      "title": "팀 프로젝트 보고서",
      "deadline": "05.25",
      "subTasks": [
        {"subtitle": "초안 작성", "description": "전체 목차 구성 및 초안 작성"},
        {"subtitle": "최종본 제출", "description": "피드백 반영하여 최종본 PDF로 제출"},
      ]
    },
    {
      "title": "앱 UI 설계",
      "deadline": "05.20",
      "subTasks": [
        {"subtitle": "홈화면 설계", "description": "Flutter로 홈화면 디자인"},
        {"subtitle": "채팅화면 구성", "description": "채팅 UI 요소 및 상태 구성"},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.tabIndex);
  }

  @override
  void didUpdateWidget(covariant TaskManageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) {
      _pageController.animateToPage(
        widget.tabIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showTaskRegisterDialog() {
    String title = "";
    String deadline = "";
    List<Map<String, String>> subTasks = [{"subtitle": "", "description": ""}];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("과제 등록"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "과제 제목"),
                    onChanged: (v) => title = v,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "마감일 (예: 05.20)"),
                    onChanged: (v) => deadline = v,
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(subTasks.length, (index) {
                      return Column(
                        children: [
                          TextField(
                            decoration: const InputDecoration(labelText: "소제목"),
                            onChanged: (v) => subTasks[index]['subtitle'] = v,
                          ),
                          TextField(
                            decoration: const InputDecoration(labelText: "설명"),
                            maxLines: 2,
                            onChanged: (v) => subTasks[index]['description'] = v,
                          ),
                        ],
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        subTasks.add({"subtitle": "", "description": ""});
                      });
                    },
                    child: const Text("소과제 추가"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    tasks.insert(0, {
                      "title": title,
                      "deadline": deadline,
                      "subTasks": subTasks,
                    });
                  });
                  Navigator.pop(context);
                },
                child: const Text("등록"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManageTab() {
    final members = ['가을', '윤지', '유진', '지후'];
    final task = tasks.isNotEmpty ? tasks[selectedTaskIndex] : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 왼쪽 리스트
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB8BDF1).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("과제 관리", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton(onPressed: _showTaskRegisterDialog, child: const Text("과제 등록")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTaskIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEBFD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(tasks[index]['title'], style: const TextStyle(fontSize: 16))),
                                Text("마감일: ${tasks[index]['deadline']}", style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),

          // 오른쪽 상세보기
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFB8BDF1).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: task == null
                  ? const Center(child: Text("과제를 선택하세요."))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("과제 제목: ${task['title']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("마감일: ${task['deadline']}", style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),
                  ...List.generate(task['subTasks'].length, (index) {
                    final sub = task['subTasks'][index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text("소제목: ${sub['subtitle']}")),
                            const SizedBox(width: 12),
                            ElevatedButton(onPressed: () {}, child: const Text("제출")),
                          ],
                        ),
                        Text("상세 설명: ${sub['description']}", style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildConfirmTab() {
    final Map<String, List<Map<String, dynamic>>> groupedTasks = {
      '5월 1일 과제': [
        {'title': '1. 마감과제', 'members': ['가을', '윤지', '지후']},
        {'title': '2. 캡처UI', 'members': ['가을', '윤지', '유진', '지후']},
      ],
      '4월 31일 과제': [
        {'title': '1. UI과제', 'members': ['가을', '윤지', '지후']},
      ],
      '4월 30일 과제': [
        {'title': '1. 녹화과제', 'members': ['가을', '윤지', '유진']},
        {'title': '2. 자료정리', 'members': ['가을', '윤지', '유진', '지후']},
      ],
      '4월 1일 과제': [
        {'title': '1. 마감과제', 'members': ['가을']},
      ],
    };

    String selectedMember = '가을';
    String selectedTaskDetail = '5월 1일 과제 - 마감과제';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 좌측 과제 리스트
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView(
                children: groupedTasks.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...entry.value.map((task) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task['title'],
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: (task['members'] as List<String>)
                                      .map((name) => Chip(label: Text(name)))
                                      .toList(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // 우측 과제 상세 내용
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedMember,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(selectedTaskDetail,
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: widget.onTabChanged,
      children: [
        _buildManageTab(),
        _buildConfirmTab(),
      ],
    );
  }
}