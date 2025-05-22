import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'pages/home.dart';

// ✅ 백그라운드 푸시 알림 수신 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('💬 백그라운드 메시지 수신됨: ${message.messageId}');
}

// ✅ navigatorKey를 사용해 어디서든 context 접근 가능하게 함
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ 로컬 알림 플러그인 전역 초기화
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.signInAnonymously();

  // 🔔 로컬 알림 초기화
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📬 포그라운드 메시지 수신됨: ${message.notification?.title}");

    final notification = message.notification;
    final android = notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'modit_channel_id', // 고유 채널 ID
            'MoDit 알림',
            channelDescription: '앱 실행 중에도 알림을 보여줍니다',
            importance: Importance.max,
            priority: Priority.high,
            color: const Color(0xFFB8BDF1),
          ),
        ),
      );
    }
  });

  runApp(const MoDitApp());
}

class MoDitApp extends StatelessWidget {
  const MoDitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
      home: const Home(),
    );
  }
}
