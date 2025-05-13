<<<<<<< HEAD
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_selector/file_selector.dart';

import 'flask_api.dart';
import 'popup_task_register.dart';

class TaskManageScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;

  const TaskManageScreen({
    required this.groupId,
    required this.currentUserEmail,
    Key? key,
  }) : super(key: key);
=======
import 'package:flutter/material.dart';

class TaskManageScreen extends StatefulWidget {
  final int tabIndex;
  final Function(int) onTabChanged;

  const TaskManageScreen({required this.tabIndex, required this.onTabChanged, Key? key}) : super(key: key);
>>>>>>> develop

  @override
  _TaskManageScreenState createState() => _TaskManageScreenState();
}

class _TaskManageScreenState extends State<TaskManageScreen> {
<<<<<<< HEAD
  final db = FirebaseDatabase.instance.ref();
  late PageController _pageController;
  int selectedTaskIndex = 0;
  int _homeworkTabIndex = 0;
  String? selectedTaskTitle;
  String? selectedSubTaskTitle;
  String? selectedUser;
  String? selectedFileType;
  String? selectedFileUrl;

  final List<Map<String, dynamic>> tasks = [];
  Map<String, Map<String, List<String>>> submissions = {}; // task -> subtask -> users
=======
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
>>>>>>> develop

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _pageController = PageController(initialPage: 0);
    loadTasks();
  }

  void loadTasks() async {
    final snapshot = await db.child('tasks').child(widget.groupId).get();

    if (snapshot.exists) {
      final Map<String, dynamic> taskData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Map<String, dynamic>> loadedTasks = [];

      taskData.forEach((taskId, taskValue) {
        final taskMap = Map<String, dynamic>.from(taskValue);

        final subTaskList = (taskMap['subTasks'] as List<dynamic>?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ?? [];

        loadedTasks.add({
          'title': taskMap['title'] ?? '',
          'deadline': taskMap['deadline'] ?? '',
          'subTasks': subTaskList,
        });
      });

      setState(() {
        tasks.clear();
        tasks.addAll(loadedTasks);
      });
    }
  }

  void loadSubmissions() async {
    final snapshot = await db.child('submissions').child(widget.groupId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((taskTitle, subMap) {
        final subTasks = Map<String, dynamic>.from(subMap);
        subTasks.forEach((subTaskTitle, userMap) {
          final users = Map<String, dynamic>.from(userMap);
          submissions[taskTitle] ??= {};
          submissions[taskTitle]![subTaskTitle] = users.keys.toList();
        });
      });
    }
  }

  Future<void> loadSubmissionFile(String user, String task, String subTask) async {
    final snapshot = await db.child('submissions').child(widget.groupId).child(task).child(subTask).child(user).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        selectedUser = user;
        selectedTaskTitle = task;
        selectedSubTaskTitle = subTask;
        selectedFileUrl = data['fileUrl'];
        selectedFileType = data['fileType'];
      });
=======
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
>>>>>>> develop
    }
  }

  void _showTaskRegisterDialog() {
<<<<<<< HEAD
    showDialog(
      context: context,
      builder: (context) => TaskRegisterPopup(groupId: widget.groupId),
    );
  }

  Future<void> _pickAndUploadFile(String groupId, String userEmail, String taskTitle, String subTaskTitle) async {
    final XFile? file = await openFile();
    if (file != null) {
      final uploaded = await Api().uploadTaskFile(
        File(file.path),
        groupId,
        userEmail,
        taskTitle,
        subTaskTitle,
      );
      if (uploaded != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("파일이 성공적으로 업로드되었습니다!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("파일 업로드 실패.")),
        );
      }
    }
  }

  Widget _buildCircleTabButton(int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _homeworkTabIndex == index
              ? const Color(0xFFB0B8FC)
              : const Color(0xFFD3D0EA),
        ),
      ),
    );
  }


  Widget _buildManageTab() {
    final task = tasks.isNotEmpty ? tasks[selectedTaskIndex] : null;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          // 왼쪽 과제 목록
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
=======
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
>>>>>>> develop
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
<<<<<<< HEAD
                      const Text('과제 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: _showTaskRegisterDialog,
                        child: Row(
                          children: [
                            const Text('과제 등록', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Image.asset('assets/images/plus_icon2.png', width: 24),
                          ],
                        ),
                      ),
=======
                      const Text("과제 관리", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton(onPressed: _showTaskRegisterDialog, child: const Text("과제 등록")),
>>>>>>> develop
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
<<<<<<< HEAD
                    child: Scrollbar(
                      child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
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
                                color: const Color(0xFFB8BDF1).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task['title'], style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text("마감일: ${task['deadline']}", style: const TextStyle(fontSize: 12)),
                                  Text("소과제 ${task['subTasks'].length}개", style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
=======
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
>>>>>>> develop
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
<<<<<<< HEAD
            child: SizedBox(
              height: 500,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8BDF1).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: task == null
                    ? const Center(child: Text("과제를 선택하세요."))
                    : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${task['title']}",
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("마감일: ${task['deadline']}", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      ...List.generate(task['subTasks'].length, (index) {
                        final sub = task['subTasks'][index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${sub['subtitle']}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                  ),
                                ),
                                const SizedBox(width: 19),
                                OutlinedButton(
                                  onPressed: () => _pickAndUploadFile(
                                    widget.groupId,
                                    widget.currentUserEmail,
                                    task['title'],
                                    sub['subtitle'],
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                                    foregroundColor: const Color(0xFF0D0A64),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("제출"),
                                ),
                              ],
                            ),
                            Text("상세 설명: ${sub['description']}", style: const TextStyle(fontSize: 17)),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // 왼쪽 과제 + 소과제 + 제출자 목록
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('제출 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: submissions.entries.map((taskEntry) {
                      final taskTitle = taskEntry.key;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(taskTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...taskEntry.value.entries.map((subTaskEntry) {
                            final subTaskTitle = subTaskEntry.key;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7E5FC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subTaskTitle,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: subTaskEntry.value.map((user) {
                                      return ElevatedButton(
                                        onPressed: () => loadSubmissionFile(user, taskTitle, subTaskTitle),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                                        child: Text(user, style: const TextStyle(color: Colors.black)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 오른쪽 상세내용 상자
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 500,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8BDF1).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: selectedUser == null
                    ? const Center(child: Text("제출된 과제를 선택하세요."))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedUser!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text("$selectedTaskTitle - $selectedSubTaskTitle",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 3.0,
                          child: selectedFileType == 'image'
                              ? Image.network(selectedFileUrl!, fit: BoxFit.contain)
                              : FutureBuilder<String>(
                            future: _loadTextFromUrl(selectedFileUrl!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return const Center(child: Text("오류 발생"));
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(snapshot.data ?? "",
                                      style: const TextStyle(fontSize: 14)),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
=======
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
>>>>>>> develop
              ),
            ),
          ),
        ],
      ),
    );
  }


<<<<<<< HEAD
  Future<String> _loadTextFromUrl(String url) async {
    final uri = Uri.parse(url);
    final response = await HttpClient().getUrl(uri).then((req) => req.close());
    final contents = await response.transform(const Utf8Decoder()).join();
    return contents;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 원형 탭 인디케이터
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircleTabButton(0),
              const SizedBox(width: 12),
              _buildCircleTabButton(1),
            ],
          ),
        ),

        // 실제 페이지
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _homeworkTabIndex = index;
              });
            },
            children: [
              _buildManageTab(),
              _buildConfirmTab(),
            ],
          ),
        ),
      ],
    );
  }

}
=======

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
>>>>>>> develop
