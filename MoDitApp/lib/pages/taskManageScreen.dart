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

  @override
  _TaskManageScreenState createState() => _TaskManageScreenState();
}

class _TaskManageScreenState extends State<TaskManageScreen> {
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
  Map<String, Map<String, List<String>>> submissions = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    loadTasks();
    loadSubmissions();
  }

  Future<void> loadTasks() async {
    final snapshot = await db.child('tasks').child(widget.groupId).get();

    if (!snapshot.exists) return;

    final data = snapshot.value;
    print("🔥 snapshot.value: $data");

    if (data is! Map) {
      print("🚨 snapshot.value가 Map이 아님: ${data.runtimeType}");
      return;
    }

    final Map<String, dynamic> taskMap = Map<String, dynamic>.from(data);
    final List<Map<String, dynamic>> loadedTasks = [];

    taskMap.forEach((taskId, taskValue) {
      if (taskValue is! Map) return;

      final taskData = Map<String, dynamic>.from(taskValue);
      final subTaskList = <Map<String, dynamic>>[];

      if (taskData['subTasks'] is Map) {
        final subTaskMap = Map<String, dynamic>.from(taskData['subTasks']);
        subTaskMap.forEach((subId, subData) {
          if (subData is! Map) return;
          final subMap = Map<String, dynamic>.from(subData);

          // submissions 파싱 추가
          Map<String, dynamic> submissions = {};
          if (subMap['submissions'] is Map) {
            submissions = Map<String, dynamic>.from(subMap['submissions']);
          }

          subTaskList.add({
            "subId": subId,
            "subtitle": subMap["subtitle"] ?? '',
            "description": subMap["description"] ?? '',
            "submissions": submissions, // 포함시켜야 과제물이 보임
          });

          print("DEBUG: taskId = $taskId, subId = $subId");
        });
      }

      loadedTasks.add({
        "taskId": taskId,
        "title": taskData['title'] ?? '',
        "deadline": taskData['deadline'] ?? '',
        "subTasks": subTaskList,
      });
    });

    setState(() {
      tasks.clear();
      tasks.addAll(loadedTasks);
    });
  }


  Future<void> registerTask(String title, String deadline, List<Map<String, String>> subTasks) async {
    final taskId = db.child('tasks').child(widget.groupId).push().key;
    if (taskId == null) return;

    final subTaskMap = <String, Map<String, String>>{};
    for (var sub in subTasks) {
      final subId = db.child('tasks').child(widget.groupId).child(taskId).child('subTasks').push().key;
      if (subId != null) subTaskMap[subId] = sub;
    }

    final taskData = {
      "title": title,
      "deadline": deadline,
      "subTasks": subTaskMap,
    };

    await db.child('tasks').child(widget.groupId).child(taskId).set(taskData);
    await loadTasks();
  }

  Future<void> loadSubmissions() async {
    final snapshot = await db.child('tasks').child(widget.groupId).get();
    if (!snapshot.exists) {
      setState(() {
        submissions = {};
      });
      return;
    }

    final Map<String, dynamic> tasksData = Map<String, dynamic>.from(snapshot.value as Map);
    final newSubmissions = <String, Map<String, List<String>>>{};

    tasksData.forEach((taskId, taskData) {
      final task = Map<String, dynamic>.from(taskData);
      final taskTitle = task['title'] ?? '';
      final subTaskMap = task['subTasks'];

      if (subTaskMap is Map) {
        subTaskMap.forEach((subId, subTaskData) {
          final sub = Map<String, dynamic>.from(subTaskData);
          final subTitle = sub['subtitle'] ?? '';
          final submissionsMap = sub['submissions'];
          if (submissionsMap is Map) {
            final userMap = Map<String, dynamic>.from(submissionsMap);
            newSubmissions[taskTitle] ??= {};
            newSubmissions[taskTitle]![subTitle] = userMap.keys.toList();
          }
        });
      }
    });

    setState(() {
      submissions = newSubmissions;
    });
  }


  Future<String> _loadTextFromUrl(String url) async {
    final uri = Uri.parse(url);
    final response = await HttpClient().getUrl(uri).then((req) => req.close());
    final contents = await response.transform(const Utf8Decoder()).join();
    return contents;
  }


  Future<void> loadSubmissionFile(String user, String taskTitle, String subTaskTitle) async {
    final task = tasks.firstWhere((t) => t['title'] == taskTitle, orElse: () => {});
    if (task.isEmpty) return;

    final sub = (task['subTasks'] as List<Map<String, dynamic>>)
        .firstWhere((s) => s['subtitle'] == subTaskTitle, orElse: () => {});
    if (sub.isEmpty) return;

    final taskId = task['taskId'];
    final subId = sub['subId'];
    final sanitizedUser = sanitizeKey(user);

    final snapshot = await db
        .child('tasks')
        .child(widget.groupId)
        .child(taskId)
        .child('subTasks')
        .child(subId)
        .child('submissions')
        .child(sanitizedUser)
        .get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        selectedUser = user;
        selectedTaskTitle = taskTitle;
        selectedSubTaskTitle = subTaskTitle;
        selectedFileUrl = data['fileUrl'];
        selectedFileType = data['fileType'];
      });
    } else {
      print("해당 제출 데이터 없음");
    }
  }


  void _showTaskRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => TaskRegisterPopup(
        groupId: widget.groupId,
        onTaskRegistered: (title, deadline, subTasks) async {
          await registerTask(title, deadline, subTasks);
          await loadTasks();
          await loadSubmissions();
        },
      ),
    );
  }

  // Firebase 경로에 쓸 수 없는 문자 제거용 유틸 함수
  String sanitizeKey(String key) {
    return key
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll('\$', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('/', '_');
  }

  Future<void> _pickAndUploadFile(
      String taskId,
      String subId,
      String userEmail,
      String groupId,
      ) async {
    final XFile? file = await openFile();
    if (file != null) {
      final uploaded = await Api().uploadTaskFile(
        File(file.path),
        groupId,
        userEmail,
        taskId,
        subId,
      );

      if (uploaded != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("파일이 성공적으로 업로드되었습니다!")),
        );

        final encodedEmail = sanitizeKey(userEmail);

        // groupId가 누락되지 않도록 경로 수정
        await db
            .child('tasks')
            .child(groupId)
            .child(taskId)
            .child('subTasks')
            .child(subId)
            .child('submissions')
            .child(encodedEmail)
            .set({
          "fileUrl": uploaded['file_url'],
          "submittedAt": DateTime.now().toIso8601String(),
          "fileType": uploaded['file_url'].toString().endsWith('.txt') ? 'text' : 'image',
        });

        await loadSubmissions();
        setState(() {});
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

  void _showTaskEditDialog(int index) {
    final task = tasks[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('과제 수정'),
          content: Text('과제 "${task['title']}" 를 수정하는 창입니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
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
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('과제 목록', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: _showTaskRegisterDialog,
                        child: Row(
                          children: [
                            const Text('과제 등록', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Image.asset('assets/images/plus_icon2.png', width: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // 정렬된 리스트로 바꿔서 표시
                  Expanded(
                    child: Scrollbar(
                      child: Builder(
                        builder: (context) {
                          final sortedTasks = List<Map<String, dynamic>>.from(tasks)
                            ..sort((a, b) => DateTime.parse(a['deadline']).compareTo(DateTime.parse(b['deadline'])));

                          return ListView.builder(
                            itemCount: sortedTasks.length,
                            itemBuilder: (context, index) {
                              final task = sortedTasks[index];
                              final originalIndex = tasks.indexOf(task); // 정렬 전 index 찾기

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedTaskIndex = originalIndex;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: selectedTaskIndex == originalIndex
                                        ? const Color(0xFF0D0A64).withOpacity(0.2)
                                        : const Color(0xFFB8BDF1).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              task['title'],
                                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _showTaskEditDialog(originalIndex); // 수정 팝업 호출
                                            },
                                            child: const Text(
                                              '수정',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF0D0A64),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text("마감일: ${task['deadline']}", style: const TextStyle(fontSize: 14)),
                                      Text("소과제 ${task['subTasks'].length}개", style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),

                                ),
                              );
                            },
                          );
                        },
                      ),
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
            child: Padding(
              padding: const EdgeInsets.only(top: 35),
              child: SizedBox( // 고정 높이를 주기 위해 SizedBox 추가
                height: 500,   // 원하는 고정 높이 설정
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8BDF1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: task == null
                      ? const Center(child: Text("과제를 선택하세요."))
                      : Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    thickness: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(task['subTasks'].length, (index) {
                            final sub = task['subTasks'][index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${index + 1}. ${sub['subtitle']}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 19),
                                    TextButton(
                                      onPressed: () => _pickAndUploadFile(
                                        task['taskId'],
                                        sub['subId'],
                                        widget.currentUserEmail,
                                        widget.groupId,
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                                      ),
                                      child: const Text(
                                        "제출",
                                        style: TextStyle(
                                          color: Color(0xFF0D0A64),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text("${sub['description']}",
                                    style: const TextStyle(fontSize: 19)),
                                const SizedBox(height: 12),
                                if (index != task['subTasks'].length - 1) ...[
                                  const Divider(
                                    thickness: 1.2,
                                    color: Colors.grey,
                                    height: 24,
                                  ),
                                ]
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          // 왼쪽 과제 + 소과제 + 제출자 목록
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('과제물 확인', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, taskIndex) {
                        final task = tasks[taskIndex];
                        final taskTitle = task['title'];
                        final subTasks = task['subTasks'] as List<Map<String, dynamic>>;

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7E5FC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(taskTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ...subTasks.map((subTask) {
                                final subTitle = subTask['subtitle']!;
                                final submitUsers = submissions[taskTitle]?[subTitle] ?? [];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(subTitle,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      submitUsers.isEmpty
                                          ? const Text("제출자 없음", style: TextStyle(color: Colors.grey))
                                          : Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: submitUsers.map((userEmail) {
                                          final sanitizedEmail = sanitizeKey(userEmail);

                                          return FutureBuilder<DataSnapshot>(
                                            future: db.child('user').child(sanitizedEmail).get(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const SizedBox(
                                                  width: 80,
                                                  height: 40,
                                                  child: CircularProgressIndicator(),
                                                );
                                              } else if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                                                return const SizedBox(
                                                  width: 80,
                                                  height: 40,
                                                  child: Text("이름 오류"),
                                                );
                                              }

                                              final userData = Map<String, dynamic>.from(snapshot.data!.value as Map);
                                              final userName = userData['name'] ?? userEmail;

                                              return OutlinedButton(
                                                onPressed: () => loadSubmissionFile(userEmail, taskTitle, subTitle),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                                                  foregroundColor: const Color(0xFF0D0A64),
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                child: Text(userName),
                                              );
                                            },
                                          );
                                        }).toList(),

                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
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
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text("$selectedTaskTitle - $selectedSubTaskTitle",
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SizedBox(
                        height: 300,
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
                                        style: const TextStyle(fontSize: 16)),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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