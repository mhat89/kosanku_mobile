import 'package:flutter/material.dart';

class UserTooltipBubble extends StatelessWidget {
  final String userName;
  final Widget child;
  final bool showTooltip;

  const UserTooltipBubble({
    Key? key,
    required this.userName,
    required this.child,
    this.showTooltip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showTooltip || userName.isEmpty) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          bottom: 50, // Posisi di atas icon dengan jarak lebih jauh
          left: -40,
          right: -40,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        // Triangle pointer
        Positioned(
          bottom: 43, // Posisi pointer tepat di bawah tooltip
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(10, 7),
              painter: TrianglePainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade800
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // Bottom center
      ..lineTo(0, 0) // Top left
      ..lineTo(size.width, 0) // Top right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}