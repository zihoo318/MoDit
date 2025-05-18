import 'package:flutter/material.dart';
import 'package:moditapp/pages/group_main_screen.dart';
import 'pages/first_page.dart';
import 'pages/logo_screen.dart';
import 'pages/meeting_calendar.dart';
import 'pages/meeting_record.dart';
import 'pages/notice.dart';
import 'pages/study_first_page.dart';
import 'pages/study_time.dart';
import 'package:moditapp/pages/chatting.dart';
import 'package:moditapp/pages/join.dart';
import 'pages/home.dart'; // ✅ 홈으로 연결
import 'pages/login.dart';
import 'pages/note_screen.dart';
import 'pages/flask_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MoDitApp());
}

class MoDitApp extends StatelessWidget {
  const MoDitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoDitApp',
      theme: ThemeData(
        fontFamily: 'nanum_round',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      home: const Home(), // ✅ 첫 화면을 Home으로 지정
    );
  }
}
