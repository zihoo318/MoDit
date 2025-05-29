import 'dart:ui';
import 'package:flutter/material.dart';

class LoadingOverlay {
  static final _key = GlobalKey<_LoadingOverlayState>();
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static bool get isVisible => _isVisible;

  static void show(BuildContext context, {String message = '로딩 중입니다...'}) {
    if (_overlayEntry != null) return;
    _isVisible = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlay(key: _key, message: message),
    );

    Overlay.of(context, rootOverlay: true)?.insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
  }
}

class _LoadingOverlay extends StatefulWidget {
  final String message;
  const _LoadingOverlay({Key? key, required this.message}) : super(key: key);

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Stack(
        children: [
          // 배경 흐림 + 어둡게
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          // 로딩 인디케이터 + 텍스트
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    fontSize: 20, // ⬅️ 글씨 키움
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none, // ⬅️ 노란줄 방지
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 1))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
