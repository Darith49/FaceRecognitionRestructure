import 'package:flutter/material.dart';

/// A modern face scanning overlay.
/// Draws a semi-transparent dark background with a clear oval punched out in the center,
/// surrounded by scanning brackets.
class FaceScannerOverlay extends StatelessWidget {
  const FaceScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FaceOverlayPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate oval size and position
    final center = Offset(size.width / 2, size.height * 0.42);
    final shortestSide = size.width < size.height ? size.width : size.height;

    // Face proportion
    final ovalWidth = shortestSide * 0.70;
    final ovalHeight = ovalWidth * 1.35;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // 2. Draw semi-transparent dark background with oval cutout
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final ovalPath = Path()..addOval(ovalRect);
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final overlayPath = Path.combine(PathOperation.difference, fullPath, ovalPath);

    canvas.drawPath(overlayPath, backgroundPaint);

    // 3. Draw scanning brackets around oval
    final bracketPaint = Paint()
      ..color = const Color(0xFF2E6FF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 28.0;
    const double padding = 10.0;

    final left = ovalRect.left - padding;
    final right = ovalRect.right + padding;
    final top = ovalRect.top - padding;
    final bottom = ovalRect.bottom + padding;

    // Top-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      bracketPaint,
    );

    // Top-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right, top)
        ..lineTo(right, top + cornerLength),
      bracketPaint,
    );

    // Bottom-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - cornerLength)
        ..lineTo(left, bottom)
        ..lineTo(left + cornerLength, bottom),
      bracketPaint,
    );

    // Bottom-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - cornerLength),
      bracketPaint,
    );

    // 4. Draw guidance label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Align your face within the frame',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        bottom + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
