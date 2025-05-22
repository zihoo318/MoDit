// menu_animated_card.dart
import 'package:flutter/material.dart';

class AnimatedCard extends StatefulWidget {
  final int index;
  final int? selectedIndex;
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onCompleted;
  final Offset targetCenter;

  const AnimatedCard({
    Key? key,
    required this.index,
    required this.selectedIndex,
    required this.child,
    required this.onTap,
    required this.onCompleted,
    required this.targetCenter,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _positionAnim;
  OverlayEntry? _overlayEntry;

  bool get _isSelected => widget.index == widget.selectedIndex;
  bool get _anySelected => widget.selectedIndex != null;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // 커지면서 중앙으로 이동하는 시간
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startOverlayAnimation() async {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final centerOffset = widget.targetCenter - Offset(size.width / 2, size.height / 2);

    _positionAnim = Tween<Offset>(begin: offset, end: centerOffset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              left: _positionAnim.value.dx,
              top: _positionAnim.value.dy,
              width: size.width,
              height: size.height,
              child: Opacity(
                opacity: 1.0 - (_controller.value * 0.4), // 1.0 → 0.5으로 점점 흐려짐
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Material(
                    color: Colors.transparent,
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    setState(() => _isAnimating = true); // 중앙 이동 시작 전 숨기기

    Overlay.of(context).insert(_overlayEntry!);

    // 기능 화면 렌더링(group_main_screen.dart) 약간 빨리 트리거 (카드 사라지기 전에)
    Future.delayed(const Duration(milliseconds: 200), () { // 커지면서 중앙으로 이동하는 시간이 n만큼 지나면 동시에 미리 시작
      if (mounted) widget.onCompleted(); // 화면 전환 setState
    });

    await _controller.forward();

    _overlayEntry?.remove();
    _overlayEntry = null;

    setState(() => _isAnimating = false); // 복원하지 않음 (이미 onCompleted에서 화면 전환)

    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_overlayEntry == null) _startOverlayAnimation();
      });
    }

    final targetScale = (_isSelected || !_anySelected) ? 1.0 : 0.5;
    final targetOpacity = (!_isSelected && _anySelected) ? 0.0 : 1.0;

    final bool shouldHideOriginal = _isSelected && _isAnimating;

    return IgnorePointer(
      ignoring: !_isSelected && _anySelected,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: targetOpacity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: targetScale),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: shouldHideOriginal
              ? const SizedBox.shrink() // 유체이탈 방지
              : GestureDetector(
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
