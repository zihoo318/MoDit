import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:moditapp/pages/popup_task_edit.dart';
import 'package:moditapp/pages/popup_task_submit_note.dart';

import 'flask_api.dart';
import 'popup_task_register.dart';

class TaskManageScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final int tabIndex;
  final ValueChanged<int>? onTabChanged;

  const TaskManageScreen({
    required this.groupId,
    required this.currentUserEmail,
    this.tabIndex = 0,
    this.onTabChanged,
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
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _submitOverlay;

  late StreamSubscription<DatabaseEvent> _tasksSubscription;

  final List<Map<String, dynamic>> tasks = [];
  Map<String, Map<String, List<String>>> submissions = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    listenToTasks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tasksSubscription.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TaskManageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _tasksSubscription.cancel();
      listenToTasks();
    }
  }

  void listenToTasks() {
    _tasksSubscription = db.child('tasks').child(widget.groupId).onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null || data is! Map) {
          setState(() {
            tasks.clear();
            submissions.clear();
          });
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
              Map<String, dynamic> submissionsMap = {};
              if (subMap['submissions'] is Map) {
                submissionsMap = Map<String, dynamic>.from(
                  subMap['submissions'],
                );
              }

              subTaskList.add({
                "subId": subId,
                "subtitle": subMap["subtitle"] ?? '',
                "description": subMap["description"] ?? '',
                "submissions": submissionsMap,
              });
            });
          }

          loadedTasks.add({
            "taskId": taskId,
            "title": taskData['title'] ?? '',
            "deadline": taskData['deadline'] ?? '',
            "subTasks": subTaskList,
          });
        });

        int newSelectedIndex = 0;
        if (loadedTasks.isNotEmpty) {
          final sortedTasks = List<Map<String, dynamic>>.from(loadedTasks)
            ..sort(
              (a, b) => DateTime.parse(
                a['deadline'],
              ).compareTo(DateTime.parse(b['deadline'])),
            );
          final firstSorted = sortedTasks.first;
          newSelectedIndex = loadedTasks.indexOf(firstSorted);
        }

        setState(() {
          tasks
            ..clear()
            ..addAll(loadedTasks);
          selectedTaskIndex = newSelectedIndex;
        });

        parseSubmissionsFromTasks(taskMap);
      },
    );
  }

  void parseSubmissionsFromTasks(Map<String, dynamic> taskMap) {
    final newSubmissions = <String, Map<String, List<String>>>{};

    taskMap.forEach((taskId, taskData) {
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

  Future<void> loadSubmissionFile(
    String user,
    String taskTitle,
    String subTaskTitle,
  ) async {
    final task = tasks.firstWhere(
      (t) => t['title'] == taskTitle,
      orElse: () => {},
    );
    if (task.isEmpty) return;

    final sub = (task['subTasks'] as List<Map<String, dynamic>>).firstWhere(
      (s) => s['subtitle'] == subTaskTitle,
      orElse: () => {},
    );
    if (sub.isEmpty) return;

    final taskId = task['taskId'];
    final subId = sub['subId'];
    final sanitizedUser = sanitizeKey(user);

    final snapshot =
        await db
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
      final nameSnapshot =
          await db.child('user').child(sanitizeKey(user)).child('name').get();
      final userName =
          nameSnapshot.exists ? nameSnapshot.value as String : user;

      setState(() {
        selectedUser = userName;
        selectedTaskTitle = taskTitle;
        selectedSubTaskTitle = subTaskTitle;
        selectedFileUrl = data['fileUrl'];
        selectedFileType = data['fileType'];
      });
    }
  }

  String sanitizeKey(String key) {
    return key
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll('\$', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('/', '_');
  }

  Future<void> registerTask(
    String title,
    String deadline,
    List<Map<String, String>> subTasks,
  ) async {
    final taskId = db.child('tasks').child(widget.groupId).push().key;
    if (taskId == null) return;

    final subTaskMap = <String, Map<String, String>>{};
    for (var sub in subTasks) {
      final subId =
          db
              .child('tasks')
              .child(widget.groupId)
              .child(taskId)
              .child('subTasks')
              .push()
              .key;
      if (subId != null) subTaskMap[subId] = sub;
    }

    final taskData = {
      "title": title,
      "deadline": deadline,
      "subTasks": subTaskMap,
    };

    await db.child('tasks').child(widget.groupId).child(taskId).set(taskData);
  }

  Future<void> updateTask(
    String taskId,
    String newTitle,
    String newDeadline,
    List<Map<String, String>> updatedSubTasks,
  ) async {
    final taskRef = db.child('tasks').child(widget.groupId).child(taskId);
    final subTasksRef = taskRef.child('subTasks');

    final snapshot = await subTasksRef.get();
    final Map<String, dynamic> existingSubTaskData =
        snapshot.exists ? Map<String, dynamic>.from(snapshot.value as Map) : {};

    final newSubTaskMap = <String, Map<String, dynamic>>{};
    final existingSubTaskIds = existingSubTaskData.keys.toList();

    for (int i = 0; i < updatedSubTasks.length; i++) {
      final sub = updatedSubTasks[i];

      if (i < existingSubTaskIds.length) {
        final oldSubId = existingSubTaskIds[i];
        final oldSub = Map<String, dynamic>.from(existingSubTaskData[oldSubId]);
        final existingSubmissions = oldSub['submissions'] ?? {};
        newSubTaskMap[oldSubId] = {
          'subtitle': sub['subtitle'] ?? '',
          'description': sub['description'] ?? '',
          'submissions': existingSubmissions,
        };
      } else {
        final newSubId = subTasksRef.push().key!;
        newSubTaskMap[newSubId] = {
          'subtitle': sub['subtitle'] ?? '',
          'description': sub['description'] ?? '',
          'submissions': {},
        };
      }
    }

    final updatedTask = {
      'title': newTitle,
      'deadline': newDeadline,
      'subTasks': newSubTaskMap,
    };

    await taskRef.set(updatedTask);
  }

  Future<void> deleteTask(String taskId) async {
    await db.child('tasks').child(widget.groupId).child(taskId).remove();
  }

  Future<void> _pickAndUploadExternalFile(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("파일이 성공적으로 업로드되었습니다!")));

        final encodedEmail = sanitizeKey(userEmail);

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
              "fileType":
                  uploaded['file_url'].toString().endsWith('.txt')
                      ? 'text'
                      : 'image',
            });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("파일 업로드 실패.")));
      }
    }
  }

  void _showTaskEditDialog(int index) async {
    final task = tasks[index];
    final result = await showAnimatedDialog<bool>(
      context: context,
      builder: (context) => TaskEditPopup(
        groupId: widget.groupId,
        initialTitle: task['title'],
        initialDeadline: task['deadline'],
        initialSubTasks: (task['subTasks'] as List)
            .map<Map<String, String>>((sub) => {
          'subtitle': sub['subtitle'] ?? '',
          'description': sub['description'] ?? '',
        })
            .toList(),
        onTaskUpdated: (newTitle, newDeadline, updatedSubTasks) async {
          await updateTask(task['taskId'], newTitle, newDeadline, updatedSubTasks);
          Navigator.pop(context, true);
        },
        onTaskDeleted: () async {
          await deleteTask(task['taskId']);
          Navigator.pop(context, true);
        },
      ),
    );

    if (result == true) setState(() {});
  }


  void _showTaskRegisterDialog() {
    showAnimatedDialog(
      context: context,
      builder: (context) => TaskRegisterPopup(
        groupId: widget.groupId,
        onTaskRegistered: (title, deadline, subTasks) async {
          await registerTask(title, deadline, subTasks);
        },
      ),
    );
  }


  // 팝업 띄우는 애니메이션
  Future<T?> showAnimatedDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
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
        width: _homeworkTabIndex == index ? 16 : 14,
        height: _homeworkTabIndex == index ? 16 : 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              _homeworkTabIndex == index
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
                      const Text(
                        '과제 목록',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showTaskRegisterDialog,
                        child: Row(
                          children: [
                            const Text('과제 등록', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Image.asset(
                              'assets/images/plus_icon2.png',
                              width: 24,
                            ),
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
                          final sortedTasks = List<Map<String, dynamic>>.from(
                            tasks,
                          )..sort(
                            (a, b) => DateTime.parse(
                              a['deadline'],
                            ).compareTo(DateTime.parse(b['deadline'])),
                          );

                          return ListView.builder(
                            itemCount: sortedTasks.length,
                            itemBuilder: (context, index) {
                              final task = sortedTasks[index];
                              final originalIndex = tasks.indexOf(
                                task,
                              ); // 정렬 전 index 찾기

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
                                    color:
                                        selectedTaskIndex == originalIndex
                                            ? const Color(
                                              0xFF0D0A64,
                                            ).withOpacity(0.2)
                                            : const Color(
                                              0xFFB8BDF1,
                                            ).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              task['title'],
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _showTaskEditDialog(
                                                originalIndex,
                                              ); // 수정 팝업 호출
                                            },
                                            child: const Text(
                                              '수정',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF0D0A64),
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "마감일: ${task['deadline']}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "소과제 ${task['subTasks'].length}개",
                                        style: const TextStyle(fontSize: 14),
                                      ),
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
              padding: const EdgeInsets.only(top: 0),
              child: SizedBox(
                height: 500,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8BDF1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      task == null
                          ? const Center(child: Text("과제를 선택하세요."))
                          : Scrollbar(
                            controller: _scrollController,
                            // ✅ 여기
                            thumbVisibility: true,
                            radius: const Radius.circular(8),
                            thickness: 6,
                            child: SingleChildScrollView(
                              controller: _scrollController, // ✅ 여기
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...List.generate(task['subTasks'].length, (
                                    index,
                                  ) {
                                    final sub = task['subTasks'][index];
                                    final LayerLink layerLink = LayerLink();
                                    OverlayEntry? localOverlay;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${index + 1}. ${sub['subtitle']}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 19),
                                            CompositedTransformTarget(
                                              link: layerLink,
                                              child: TextButton(
                                                onPressed: () {
                                                  if (localOverlay != null) {
                                                    localOverlay!.remove();
                                                    localOverlay = null;
                                                  } else {
                                                    final overlay = Overlay.of(
                                                      context,
                                                    );
                                                    localOverlay = OverlayEntry(
                                                      builder:
                                                          (context) => Stack(
                                                            children: [
                                                              Positioned.fill(
                                                                child: GestureDetector(
                                                                  onTap: () {
                                                                    localOverlay
                                                                        ?.remove();
                                                                    localOverlay =
                                                                        null;
                                                                  },
                                                                  behavior:
                                                                      HitTestBehavior
                                                                          .translucent,
                                                                ),
                                                              ),
                                                              Positioned(
                                                                width: 200,
                                                                child: CompositedTransformFollower(
                                                                  link:
                                                                      layerLink,
                                                                  showWhenUnlinked:
                                                                      false,
                                                                  offset:
                                                                      const Offset(
                                                                        3,
                                                                        1,
                                                                      ),
                                                                  followerAnchor:
                                                                      Alignment
                                                                          .topRight,
                                                                  targetAnchor:
                                                                      Alignment
                                                                          .bottomRight,
                                                                  child: Material(
                                                                    elevation:
                                                                        0,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                    child: Container(
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(
                                                                          0xFFF9F9FD,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                      ),
                                                                      child: Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          InkWell(
                                                                            onTap: () async {
                                                                              localOverlay?.remove();
                                                                              localOverlay =
                                                                                  null;

                                                                              final result = await showNoteSubmitPopup(
                                                                                context:
                                                                                    context,
                                                                                userEmail:
                                                                                    widget.currentUserEmail,
                                                                                taskId:
                                                                                    task['taskId'],
                                                                                subId:
                                                                                    sub['subId'],
                                                                                groupId:
                                                                                    widget.groupId,
                                                                              );

                                                                              if (result ==
                                                                                  true) {
                                                                                ScaffoldMessenger.of(
                                                                                  context,
                                                                                ).showSnackBar(
                                                                                  const SnackBar(
                                                                                    content: Text(
                                                                                      '노트가 성공적으로 제출되었습니다',
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              } else if (result ==
                                                                                  false) {
                                                                                ScaffoldMessenger.of(
                                                                                  context,
                                                                                ).showSnackBar(
                                                                                  const SnackBar(
                                                                                    content: Text(
                                                                                      '노트 제출에 실패했습니다',
                                                                                    ),
                                                                                    backgroundColor:
                                                                                        Colors.red,
                                                                                  ),
                                                                                );
                                                                              }
                                                                            },
                                                                            child: const Padding(
                                                                              padding: EdgeInsets.all(
                                                                                12,
                                                                              ),
                                                                              child: Text(
                                                                                "📓 모딧 노트 제출",
                                                                                style: TextStyle(
                                                                                  color: Color(
                                                                                    0xFF0D0A64,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            height:
                                                                                1,
                                                                            color: const Color(
                                                                              0xFF0D0A64,
                                                                            ),
                                                                          ),
                                                                          InkWell(
                                                                            onTap: () async {
                                                                              await _pickAndUploadExternalFile(
                                                                                task['taskId'],
                                                                                sub['subId'],
                                                                                widget.currentUserEmail,
                                                                                widget.groupId,
                                                                              );
                                                                              localOverlay?.remove();
                                                                              localOverlay =
                                                                                  null;
                                                                            },
                                                                            child: const Padding(
                                                                              padding: EdgeInsets.all(
                                                                                12,
                                                                              ),
                                                                              child: Text(
                                                                                "📁 외부 파일 선택",
                                                                                style: TextStyle(
                                                                                  color: Color(
                                                                                    0xFF0D0A64,
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
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                    overlay.insert(
                                                      localOverlay!,
                                                    );
                                                  }
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.white
                                                      .withOpacity(0.6),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 1,
                                                      ),
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
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "${sub['description']}",
                                          style: const TextStyle(fontSize: 19),
                                        ),
                                        const SizedBox(height: 12),
                                        if (index !=
                                            task['subTasks'].length - 1)
                                          const Divider(
                                            thickness: 1.2,
                                            color: Colors.grey,
                                            height: 24,
                                          ),
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
                const Text(
                  '과제물 확인',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Scrollbar(
                    child: Builder(
                      builder: (context) {
                        final sortedTasks = List<Map<String, dynamic>>.from(
                          tasks,
                        )..sort(
                          (a, b) => DateTime.parse(
                            a['deadline'],
                          ).compareTo(DateTime.parse(b['deadline'])),
                        );

                        return ListView.builder(
                          itemCount: sortedTasks.length,
                          itemBuilder: (context, taskIndex) {
                            final task = sortedTasks[taskIndex];
                            final taskTitle = task['title'];
                            final subTasks =
                                task['subTasks'] as List<Map<String, dynamic>>;

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
                                  Text(
                                    taskTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...subTasks.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final subTask = entry.value;
                                    final subTitle = subTask['subtitle'] ?? '';
                                    final submitUsers =
                                        submissions[taskTitle]?[subTitle] ?? [];

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "  ${index + 1}. $subTitle",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 11,
                                            ),
                                            child:
                                                submitUsers.isEmpty
                                                    ? const Text(
                                                      "제출자 없음",
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    )
                                                    : Wrap(
                                                      spacing: 8,
                                                      runSpacing: 4,
                                                      children:
                                                          submitUsers.map((
                                                            userEmail,
                                                          ) {
                                                            final sanitizedEmail =
                                                                sanitizeKey(
                                                                  userEmail,
                                                                );
                                                            return FutureBuilder<
                                                              DataSnapshot
                                                            >(
                                                              future:
                                                                  db
                                                                      .child(
                                                                        'user',
                                                                      )
                                                                      .child(
                                                                        sanitizedEmail,
                                                                      )
                                                                      .get(),
                                                              builder: (
                                                                context,
                                                                snapshot,
                                                              ) {
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .waiting) {
                                                                  return const SizedBox(
                                                                    width: 80,
                                                                    height: 40,
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  );
                                                                } else if (snapshot
                                                                        .hasError ||
                                                                    !snapshot
                                                                        .hasData ||
                                                                    !snapshot
                                                                        .data!
                                                                        .exists) {
                                                                  return const SizedBox(
                                                                    width: 80,
                                                                    height: 40,
                                                                    child: Text(
                                                                      "이름 오류",
                                                                    ),
                                                                  );
                                                                }

                                                                final userData = Map<
                                                                  String,
                                                                  dynamic
                                                                >.from(
                                                                  snapshot
                                                                          .data!
                                                                          .value
                                                                      as Map,
                                                                );
                                                                final userName =
                                                                    userData['name'] ??
                                                                    userEmail;

                                                                return OutlinedButton(
                                                                  onPressed:
                                                                      () => loadSubmissionFile(
                                                                        userEmail,
                                                                        taskTitle,
                                                                        subTitle,
                                                                      ),
                                                                  style: OutlinedButton.styleFrom(
                                                                    side: const BorderSide(
                                                                      color: Color(
                                                                        0xFF0D0A64,
                                                                      ),
                                                                      width:
                                                                          1.2,
                                                                    ),
                                                                    foregroundColor:
                                                                        const Color(
                                                                          0xFF0D0A64,
                                                                        ),
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          1,
                                                                    ),
                                                                    visualDensity:
                                                                        const VisualDensity(
                                                                          horizontal:
                                                                              0,
                                                                          vertical:
                                                                              -2,
                                                                        ),
                                                                    tapTargetSize:
                                                                        MaterialTapTargetSize
                                                                            .shrinkWrap,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    userName,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          }).toList(),
                                                    ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child:
                      selectedUser == null
                          ? const Center(
                            key: ValueKey("no_user"),
                            child: Text("제출된 과제를 선택하세요."),
                          )
                          : Column(
                            key: ValueKey(selectedUser),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedUser!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "$selectedTaskTitle - $selectedSubTaskTitle",
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final boxWidth = constraints.maxWidth;
                                    final boxHeight = constraints.maxHeight;

                                    return Center(
                                      child: SizedBox(
                                        width: boxWidth,
                                        height: boxHeight,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          child: InteractiveViewer(
                                            panEnabled: true,
                                            minScale: 0.5,
                                            maxScale: 3.0,
                                            child:
                                                selectedFileType == 'image'
                                                    ? Image.network(
                                                      selectedFileUrl!,
                                                      fit: BoxFit.fill,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    )
                                                    : FutureBuilder<String>(
                                                      future: _loadTextFromUrl(
                                                        selectedFileUrl!,
                                                      ),
                                                      builder: (
                                                        context,
                                                        snapshot,
                                                      ) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return const Center(
                                                            child: Text(
                                                              "오류 발생",
                                                            ),
                                                          );
                                                        } else {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8.0,
                                                                ),
                                                            child: Text(
                                                              snapshot.data ??
                                                                  "",
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                          ),
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
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _homeworkTabIndex = index;
              });
            },
            children: [_buildManageTab(), _buildConfirmTab()],
          ),
        ),
      ],
    );
  }
}
