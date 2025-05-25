import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moditapp/pages/login.dart';
import 'first_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> particles;

  @override
  void initState() {
    super.initState();

    // 무작위 파티클 15개 생성
    particles = List.generate(15, (_) => _Particle.random());

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    // ✅ FirebaseAuth 내부 초기화 기다림
    await FirebaseAuth.instance.authStateChanges().first;

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null && !user.isAnonymous && user.email != null) {
      final email = user.email!;
      final name = await getUserName(email);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            currentUserEmail: email,
            currentUserName: name ?? 'Unknown',
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 폭죽 점 애니메이션
              ...particles.map((p) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final t = Curves.easeOut.transform(_controller.value);
                    final dx = p.offset.dx * t;
                    final dy = p.offset.dy * t;

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Opacity(
                        opacity: (1 - t),
                        child: Container(
                          width: p.size,
                          height: p.size,
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              // 로고 흔들림
              Container(
                padding: const EdgeInsets.all(40),
                child: Image.asset('assets/images/logo.png', width: 180),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shake(duration: 800.ms, hz: 1.5, offset: const Offset(12, 0)),
            ],
          ),
        ),
      ),
    );
  }
}

// 폭죽 점 데이터 클래스
class _Particle {
  final Offset offset;
  final Color color;
  final double size;

  _Particle({
    required this.offset,
    required this.color,
    required this.size,
  });

  static _Particle random() {
    final rand = Random();
    final angle = rand.nextDouble() * 2 * pi;
    final distance = 40 + rand.nextDouble() * 80;
    final dx = cos(angle) * distance;
    final dy = sin(angle) * distance;
    final size = 6 + rand.nextDouble() * 6;

    final color = [
      const Color(0xFFB8BDF1),
      const Color(0xFF9FA8DA),
      const Color(0xFFD1C4E9),
      const Color(0xFF7986CB),
    ][rand.nextInt(4)];

    return _Particle(
      offset: Offset(dx, dy),
      color: color,
      size: size,
    );
  }
}

// 사용자 이름을 DB에서 가져오는 함수
Future<String?> getUserName(String email) async {
  final db = FirebaseDatabase.instance.ref();
  final sanitizedEmail = email.replaceAll('.', '_');
  final snapshot = await db.child('user').child(sanitizedEmail).child('name').get();

  if (snapshot.exists) {
    return snapshot.value as String;
  }
  return null;
}
