import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';

class APErrorWidget extends StatelessWidget {
  const APErrorWidget({
    super.key,
    this.title = 'ERROR 404!',
    this.subtitle =
        'The page you are looking for does not exist or may be under construction',
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CartIllustration(),
          Gap(24.h),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: InvAPColors.kPrimaryTextColor,
                ),
          ),
          Gap(10.h),
          SizedBox(
            width: 380.w,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InvAPColors.kSecondaryTextColor,
                  ),
            ),
          ),
          if (onRetry != null) ...[
            Gap(20.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded,
                  size: 18.sp, color: InvAPColors.kPrimaryColor),
              label: Text(
                'Try again',
                style: TextStyle(
                  color: InvAPColors.kPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shopping-cart + walking-person illustration built from Flutter icons.
class _CartIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFC107);
    const green = InvAPColors.kPrimaryColor;
    const cartOutline = Color(0xFFB0BEC5);

    final size = 140.w;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // --- Cart body ---
          Positioned(
            bottom: 0,
            left: size * 0.18,
            child: Icon(
              Icons.shopping_cart_outlined,
              size: size * 0.70,
              color: cartOutline,
            ),
          ),

          // --- Person torso (yellow shirt) ---
          Positioned(
            top: size * 0.04,
            left: size * 0.10,
            child: Container(
              width: size * 0.30,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: amber,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.15),
                  topRight: Radius.circular(size * 0.15),
                  bottomLeft: Radius.circular(size * 0.06),
                  bottomRight: Radius.circular(size * 0.06),
                ),
              ),
            ),
          ),

          // --- Head ---
          Positioned(
            top: 0,
            left: size * 0.14,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: const BoxDecoration(
                color: Color(0xFFD4A76A),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // --- Hat (green cap) ---
          Positioned(
            top: 0,
            left: size * 0.12,
            child: Container(
              width: size * 0.26,
              height: size * 0.11,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.13),
                  topRight: Radius.circular(size * 0.13),
                ),
              ),
            ),
          ),

          // --- Shorts (green) ---
          Positioned(
            top: size * 0.38,
            left: size * 0.08,
            child: Container(
              width: size * 0.34,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(size * 0.04),
              ),
            ),
          ),

          // --- Left leg ---
          Positioned(
            top: size * 0.60,
            left: size * 0.10,
            child: Container(
              width: size * 0.10,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),

          // --- Right leg (stepped forward) ---
          Positioned(
            top: size * 0.55,
            left: size * 0.24,
            child: Container(
              width: size * 0.10,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),

          // --- Left shoe ---
          Positioned(
            bottom: size * 0.04,
            left: size * 0.06,
            child: Container(
              width: size * 0.16,
              height: size * 0.07,
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                borderRadius: BorderRadius.circular(size * 0.035),
              ),
            ),
          ),

          // --- Right shoe ---
          Positioned(
            bottom: size * 0.01,
            left: size * 0.20,
            child: Container(
              width: size * 0.16,
              height: size * 0.07,
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                borderRadius: BorderRadius.circular(size * 0.035),
              ),
            ),
          ),

          // --- Arm pushing cart ---
          Positioned(
            top: size * 0.28,
            left: size * 0.35,
            child: Container(
              width: size * 0.22,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A76A),
                borderRadius: BorderRadius.circular(size * 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
