// Single tab/action item primitive
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_constants/ap_colors.dart';

class AppBarItem extends StatelessWidget {
  const AppBarItem({super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  @override
  Widget build(BuildContext context) {
    final color = isActive ? InvAPColors.kPrimaryColor : InvAPColors.kPrimaryTextColor;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          ImageIcon(AssetImage(icon), color: color),
          SizedBox(width: 6.w),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
