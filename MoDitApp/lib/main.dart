import 'package:flutter/material.dart';
import 'pages/first_page.dart'; // HomeScreen이 정의된 파일
import 'pages/logo_screen.dart';
import 'pages/meeting_calendar.dart';
import 'pages/meeting_record.dart';
import 'pages/meeting_schedule.dart';
import 'pages/notice.dart';
import 'pages/study_first_page.dart';
import 'pages/study_time.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MoDitApp()); // 이름 바꿔도 되고 그대로 사용해도 됨
}

class MoDitApp extends StatelessWidget {
  const MoDitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MeetingSchedulePage(), // ← study_time.dart의 StudyTimeScreen() 할때만 앞의 const 지우고 실행시켜야됨
    );
  }
}
