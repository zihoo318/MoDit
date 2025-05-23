import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moditapp/pages/login.dart';

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

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
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
