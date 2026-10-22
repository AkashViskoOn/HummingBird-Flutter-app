import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';

/// Signature artwork for outgoing (sent) bubbles.
///
/// Paints, clipped to the bubble radius:
///  - a whisper glass sweep across the bubble (premium glass feel),
///  - a soft organic wing/feather lobe growing from the top-right corner,
///  - a tiny monochrome hummingbird watermark inside the wing curve.
class BrandBubbleArtwork extends StatelessWidget {
  final BorderRadius radius;
  final double markSize;
  final double markOpacity;
  final EdgeInsets markOffset;

  const BrandBubbleArtwork({
    super.key,
    required this.radius,
    this.markSize = 17,
    this.markOpacity = 0.28,
    this.markOffset = const EdgeInsets.only(top: 8, right: 10),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: BrandWingPainter()),
            ),
            Positioned(
              top: markOffset.top.r,
              right: markOffset.right.r,
              child: Opacity(
                opacity: markOpacity,
                child: CustomPaint(
                  size: Size(markSize.r, markSize.r),
                  painter: HummingbirdMarkPainter(
                    color: CustomColor.kBrandAccent,
                    strokeWidth: 1.1.r,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flowing hummingbird wing / feather shape anchored in the top-right corner.
class BrandWingPainter extends CustomPainter {
  const BrandWingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // ── Whisper glass sweep (whole bubble) ──────────────────────────────────
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomColor.kBrandAccent.withValues(alpha: 0.045),
            Colors.transparent,
            CustomColor.kBrandAccent.withValues(alpha: 0.03),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // ── Wing feather lobe ───────────────────────────────────────────────────
    final wing = Path()
      ..moveTo(w * 0.99, h * 0.045)
      ..cubicTo(w * 0.80, h * 0.02, w * 0.62, h * 0.03, w * 0.52, h * 0.085)
      ..cubicTo(w * 0.44, h * 0.135, w * 0.42, h * 0.22, w * 0.47, h * 0.28)
      ..cubicTo(w * 0.53, h * 0.345, w * 0.66, h * 0.34, w * 0.78, h * 0.295)
      ..cubicTo(w * 0.90, h * 0.245, w * 0.99, h * 0.16, w * 0.99, h * 0.16)
      ..close();

    canvas.drawPath(
      wing,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            CustomColor.kBrandLight.withValues(alpha: 0.32),
            CustomColor.kBrandBorder.withValues(alpha: 0.16),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // ── Wing leading-edge highlight ─────────────────────────────────────────
    final edge = Path()
      ..moveTo(w * 0.99, h * 0.045)
      ..cubicTo(w * 0.80, h * 0.02, w * 0.62, h * 0.03, w * 0.52, h * 0.085)
      ..cubicTo(w * 0.44, h * 0.135, w * 0.42, h * 0.22, w * 0.47, h * 0.28);
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2.r
        ..strokeCap = StrokeCap.round
        ..color = CustomColor.kBrandPrimary.withValues(alpha: 0.22),
    );

    // ── Wing soft outline ───────────────────────────────────────────────────
    canvas.drawPath(
      wing,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.r
        ..strokeCap = StrokeCap.round
        ..color = CustomColor.kBrandBorder.withValues(alpha: 0.40),
    );

    // ── Feather barbs ───────────────────────────────────────────────────────
    final barbPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8.r
      ..strokeCap = StrokeCap.round
      ..color = CustomColor.kBrandPrimary.withValues(alpha: 0.14);
    for (var i = 0; i < 3; i++) {
      final t = 0.35 + i * 0.17;
      final bx = w * (0.99 - t * 0.42);
      final by = h * (0.075 + t * 0.17);
      final barb = Path()
        ..moveTo(bx, by)
        ..quadraticBezierTo(
          bx - w * 0.045,
          by + h * 0.045,
          bx - w * 0.10,
          by + h * 0.07,
        );
      canvas.drawPath(barb, barbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BrandWingPainter oldDelegate) => false;
}

/// Minimal monochrome hummingbird mark (stroked line art).
class HummingbirdMarkPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const HummingbirdMarkPainter({
    required this.color,
    this.strokeWidth = 1.1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = size.shortestSide;
    Offset c(double x, double y) => Offset(x * s / 40, y * s / 40);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    // beak
    canvas.drawLine(c(25, 15), c(35, 11), stroke);

    // head + body
    final body = Path()
      ..moveTo(24, 15)
      ..quadraticBezierTo(21.5, 11.5, 17.5, 13)
      ..quadraticBezierTo(12.5, 15, 9, 17)
      ..quadraticBezierTo(5.5, 19, 4.5, 21.5);
    canvas.drawPath(body, stroke);

    // swept wing
    final wing = Path()
      ..moveTo(18, 15)
      ..cubicTo(19.5, 9, 23.5, 5.5, 28.5, 5)
      ..cubicTo(25.5, 8.5, 24, 12, 22.5, 15);
    canvas.drawPath(wing, stroke);

    // tail fan
    canvas.drawPath(
      Path()
        ..moveTo(5.5, 19.5)
        ..lineTo(2, 21.5),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(5.3, 20.5)
        ..lineTo(2, 23.5),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(5.5, 21.5)
        ..lineTo(3, 25),
      stroke,
    );

    // eye
    canvas.drawCircle(c(23, 13.5), 0.6 * s / 40, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant HummingbirdMarkPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
