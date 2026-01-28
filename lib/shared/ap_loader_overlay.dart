import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:nb_utils/nb_utils.dart';

import '../generated/assets.dart';

class APOverlayLoader extends StatefulWidget {
  const APOverlayLoader({super.key});

  @override
  State<APOverlayLoader> createState() => _APOverlayLoaderState();
}

class _APOverlayLoaderState extends State<APOverlayLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: 800.milliseconds)
      ..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.2,
      end: 0.30,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Container(
        height: 89.h,
        width: 89.h,
        padding: EdgeInsets.all(15.w),
        decoration: const BoxDecoration(
          color: InvAPColors.kWhiteColor,
          shape: BoxShape.circle,
        ),
        child: Align(
          child: Image.asset(
            Assets.iconsDashbordIcon,
            color: InvAPColors.kPrimaryColor,
            height: 69.h,
          ),
        ),
      ),
    );
  }
}