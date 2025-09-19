import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  final Color? color;
  final double size;
  
  const LoadingWidget({
    super.key,
    this.color,
    this.size = 40.0,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_animation.value * 0.7),
          child: Image.asset(
            'assets/markers/kosan.png',
            width: widget.size,
            height: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}