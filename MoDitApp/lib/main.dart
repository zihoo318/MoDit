import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/join.dart';
import 'pages/group_main_screen.dart';
import 'pages/study_time.dart';
import 'pages/study_first_page.dart';
import 'pages/meeting_calendar.dart';
import 'pages/meeting_record.dart';
import 'pages/note_screen.dart';
import 'pages/notice.dart';
import 'pages/chatting.dart';
import 'pages/flask_test.dart';
import 'pages/first_page.dart';
import 'pages/logo_screen.dart';

/// ✅ 백그라운드 푸시 알림 수신 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('💬 백그라운드 메시지 수신됨: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ 알림 권한 요청
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ 포그라운드 메시지 처리 리스너 등록
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📬 포그라운드 메시지 수신됨: ${message.notification?.title}");
    // Flutter 앱 내에서 사용자에게 알림 표시
    if (message.notification != null) {
      // 이건 Snackbar 예시지만, flutter_local_notifications로 커스텀 알림도 가능
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.notification?.body ?? '새 메시지가 도착했습니다'),
              backgroundColor: const Color(0xFFECE6F0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      });
    }
  });

  runApp(const MoDitApp());
}

// ✅ navigatorKey를 사용해 어디서든 context 접근 가능하게 함
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MoDitApp extends StatelessWidget {
  const MoDitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ 추가
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
      home: const Home(), // ✅ 첫 진입화면
    );
  }
}
