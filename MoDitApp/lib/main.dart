import 'package:flutter/material.dart';
import 'pages/first_page.dart';
import 'pages/logo_screen.dart';
import 'pages/meeting_calendar.dart';
import 'pages/meeting_record.dart';
import 'pages/meeting_schedule.dart';
import 'pages/notice.dart';
import 'pages/study_first_page.dart';
import 'pages/study_time.dart';
import 'package:moditapp/pages/chatting.dart';
import 'package:moditapp/pages/homeworkManager.dart';
import 'package:moditapp/pages/homwork.dart';
import 'package:moditapp/pages/join.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← 요거 추가!

// s
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('ko_KR', null); // ← 이 줄 추가!
    runApp(const MoDitApp());
}

class MoDitApp extends StatelessWidget {
  const MoDitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoDitApp',
      theme: ThemeData(),

      // 기본 첫 화면
      initialRoute: '/notice',

      // 라우팅 정의
      routes: {
        '/schedule': (context) => const MeetingSchedulePage(),
        '/calendar': (context) => const MeetingCalendarScreen(),

        // 기존 페이지들도 필요 시 여기에 추가
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/study_first': (context) => const StudyFirstPage(),
        '/study_time': (context) => StudyTimeScreen(),
        '/logo': (context) => const LogoScreen(),
        '/notice': (context) => const NoticePage(),
        // ... 추가적으로 연결할 라우트 있으면 여기에 계속 확장
      },
    );
  }
}
