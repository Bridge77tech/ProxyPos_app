import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';

class APEmptyProductsWidget extends StatelessWidget {
  const APEmptyProductsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShoppingIllustration(),
          Gap(28.h),
          Text(
            'Get Started!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: InvAPColors.kPrimaryTextColor,
                ),
          ),
          Gap(10.h),
          SizedBox(
            width: 360.w,
            child: Text(
              'Your most purchased page cannot wait to be filled. Make that sale',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InvAPColors.kSecondaryTextColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Soft teal palette matching the screenshot
    const teal = Color(0xFF7ECAC3);
    const tealLight = Color(0xFFB2DFDB);
    const tealDark = Color(0xFF4DB6AC);
    const shadow = Color(0xFFD0EFEC);

    final w = 140.w;

    return SizedBox(
      width: w * 1.3,
      height: w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Shadow ellipse ──
          Positioned(
            bottom: 0,
            left: w * 0.10,
            child: Container(
              width: w * 1.05,
              height: w * 0.10,
              decoration: BoxDecoration(
                color: shadow,
                borderRadius: BorderRadius.circular(w * 0.05),
              ),
            ),
          ),

          // ══════════════════════════════
          //  SHOPPING CART (left)
          // ══════════════════════════════

          // Cart body
          Positioned(
            left: w * 0.04,
            top: w * 0.28,
            child: Container(
              width: w * 0.52,
              height: w * 0.38,
              decoration: BoxDecoration(
                color: tealLight,
                border: Border.all(color: teal, width: 2),
                borderRadius: BorderRadius.circular(w * 0.04),
              ),
              // Horizontal stripes inside cart
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (_) => Container(
                    height: 2,
                    margin: EdgeInsets.symmetric(horizontal: w * 0.04),
                    color: teal.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          // Cart handle bar
          Positioned(
            left: w * 0.01,
            top: w * 0.29,
            child: Container(
              width: w * 0.14,
              height: 2.5,
              color: tealDark,
            ),
          ),

          // Cart left wheel
          Positioned(
            left: w * 0.10,
            bottom: w * 0.04,
            child: Container(
              width: w * 0.10,
              height: w * 0.10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tealDark, width: 2.5),
                color: Colors.white,
              ),
            ),
          ),

          // Cart right wheel
          Positioned(
            left: w * 0.38,
            bottom: w * 0.04,
            child: Container(
              width: w * 0.10,
              height: w * 0.10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tealDark, width: 2.5),
                color: Colors.white,
              ),
            ),
          ),

          // ══════════════════════════════
          //  SPEECH BUBBLE (above cart)
          // ══════════════════════════════
          Positioned(
            left: w * 0.18,
            top: 0,
            child: _SpeechBubble(
              width: w * 0.54,
              height: w * 0.28,
              color: teal,
            ),
          ),

          // ══════════════════════════════
          //  HAND BASKET (right)
          // ══════════════════════════════

          // Basket handle arc
          Positioned(
            right: w * 0.02,
            top: w * 0.22,
            child: CustomPaint(
              size: Size(w * 0.36, w * 0.16),
              painter: _ArcPainter(color: tealDark, strokeWidth: 3),
            ),
          ),

          // Basket body
          Positioned(
            right: w * 0.01,
            top: w * 0.34,
            child: Container(
              width: w * 0.38,
              height: w * 0.40,
              decoration: BoxDecoration(
                color: tealLight,
                border: Border.all(color: teal, width: 2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(w * 0.04),
                  bottomRight: Radius.circular(w * 0.04),
                ),
              ),
              // Vertical stripes inside basket
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (_) => Container(
                    width: 2,
                    color: teal.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          // Basket top rim
          Positioned(
            right: w * 0.01,
            top: w * 0.34,
            child: Container(
              width: w * 0.38,
              height: w * 0.055,
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(w * 0.02),
                  topRight: Radius.circular(w * 0.02),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded rectangle speech bubble with a small tail at the bottom-left.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height + width * 0.12),
      painter: _BubblePainter(color: color),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.18;
    final tailH = size.height * 0.15;
    final bodyH = size.height - tailH;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, bodyH),
        Radius.circular(r),
      ))
      // Tail
      ..moveTo(size.width * 0.22, bodyH)
      ..lineTo(size.width * 0.16, bodyH + tailH)
      ..lineTo(size.width * 0.34, bodyH)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}

/// Draws an arc to represent the basket handle.
class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.color, required this.strokeWidth});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, 3.14159, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}
