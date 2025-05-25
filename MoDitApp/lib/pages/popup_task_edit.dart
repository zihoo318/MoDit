import 'dart:ui';
import 'package:flutter/material.dart';

class TaskEditPopup extends StatelessWidget {
  final String groupId;
  final String initialTitle;
  final String initialDeadline;
  final List<Map<String, String>> initialSubTasks;
  final void Function(String newTitle, String newDeadline, List<Map<String, String>> updatedSubTasks) onTaskUpdated;
  final VoidCallback onTaskDeleted;

  const TaskEditPopup({
    super.key,
    required this.groupId,
    required this.initialTitle,
    required this.initialDeadline,
    required this.initialSubTasks,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: TaskEditDialogContent(
                initialTitle: initialTitle,
                initialDeadline: initialDeadline,
                initialSubTasks: initialSubTasks,
                onTaskUpdated: onTaskUpdated,
                onTaskDeleted: onTaskDeleted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TaskEditDialogContent extends StatefulWidget {
  final String initialTitle;
  final String initialDeadline;
  final List<Map<String, String>> initialSubTasks;
  final void Function(String, String, List<Map<String, String>>) onTaskUpdated;
  final VoidCallback onTaskDeleted;

  const TaskEditDialogContent({
    super.key,
    required this.initialTitle,
    required this.initialDeadline,
    required this.initialSubTasks,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  });

  @override
  State<TaskEditDialogContent> createState() => _TaskEditDialogContentState();
}

class _TaskEditDialogContentState extends State<TaskEditDialogContent> {
  late String title;
  late String deadline;
  int selectedIndex = 0;
  late List<Map<String, String>> subTasks;

  @override
  void initState() {
    super.initState();
    title = widget.initialTitle;
    deadline = widget.initialDeadline;
    subTasks = List<Map<String, String>>.from(widget.initialSubTasks);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("✏️ 과제 수정", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 제목, 마감일, 소과제 목록
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: "과제 제목"),
                      onChanged: (v) => title = v,
                      controller: TextEditingController(text: title),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "마감일"),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(deadline) ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          locale: const Locale("ko", "KR"),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            deadline =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      controller: TextEditingController(text: deadline),
                    ),
                    const SizedBox(height: 16),
                    const Text("소과제 목록"),
                    const SizedBox(height: 6),
                    Column(
                      children: List.generate(subTasks.length, (index) {
                        final isSelected = selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected ? Border.all(color: const Color(0xFF0D0A64), width: 1.5) : null,
                                  ),
                                  child: Text(
                                    subTasks[index]['subtitle']!.isEmpty ? "소과제 ${index + 1}" : subTasks[index]['subtitle']!,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF0D0A64) : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    subTasks.removeAt(index);
                                    if (selectedIndex >= subTasks.length) {
                                      selectedIndex = subTasks.length - 1;
                                    }
                                  });
                                },
                                child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          subTasks.add({"subtitle": "", "description": ""});
                          selectedIndex = subTasks.length - 1;
                        });
                      },
                      child: Row(
                        children: [
                          const Text('소과제 추가', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Image.asset('assets/images/plus_icon2.png', width: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // 오른쪽: 소과제 입력
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("소과제 ${selectedIndex + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: "소제목"),
                      onChanged: (v) => subTasks[selectedIndex]['subtitle'] = v,
                      controller: TextEditingController(text: subTasks[selectedIndex]['subtitle']),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: "설명"),
                      maxLines: 3,
                      onChanged: (v) => subTasks[selectedIndex]['description'] = v,
                      controller: TextEditingController(text: subTasks[selectedIndex]['description']),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 하단 버튼 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  widget.onTaskDeleted();
                  Navigator.pop(context, true);
                },
                child: Row(
                  children: const [
                    Icon(Icons.delete_forever, color: Colors.redAccent, size: 17),
                    SizedBox(width: 2),
                    Text("전체 삭제", style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                      foregroundColor: const Color(0xFF0D0A64),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("취소"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      widget.onTaskUpdated(title, deadline, subTasks);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                      foregroundColor: const Color(0xFF0D0A64),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("수정"),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
