// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:gap/gap.dart';
//
// import '../../../../../../../core/app_constants/ap_colors.dart';
// import '../../../../../../../core/app_constants/inv_app_constants.dart';
// import '../../../../../../../generated/assets.dart';
//
// class CartItemCard extends StatelessWidget {
//   const CartItemCard({
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 10.h),
//       width: 1.sw,
//       padding: EdgeInsets.symmetric(
//         horizontal: 10.w,
//         vertical: 8.h,
//       ),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: InvAPColors.kBorderColor,
//           width: 0.7.w,
//         ),
//         borderRadius: BorderRadius.circular(8.r),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment:
//             MainAxisAlignment.spaceBetween,
//             children: [
//               Text("#1", style: Theme.of(context).textTheme.bodySmall,),
//               InkWell(
//                 onTap: () {},
//                 child: Image.asset(
//                   Assets.iconsDeleteIcon,
//                   scale: 5,
//                 ),
//               ),
//             ],
//           ),
//           Divider(
//             endIndent: 0,
//             indent: 0,
//             color: InvAPColors.kBorderColor,
//             thickness: 0.7.w,
//           ),
//           Gap(5.h),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                   CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       "Nestle Nido Essential",
//                       style: Theme.of(
//                         context,
//                       ).textTheme.bodySmall,
//                     ),
//                     Text(
//                       "Tin 150g",
//                       style: Theme.of(context)
//                           .textTheme
//                           .bodySmall!
//                           .copyWith(
//                         color: InvAPColors
//                             .kSecondaryTextColor,
//                       ),
//                     ),
//                     Text(
//                       "${InvAppConstants.kGHC} 100.00",
//                       style: Theme.of(context)
//                           .textTheme
//                           .bodySmall!
//                           .copyWith(
//                         color:
//                         InvAPColors.kPrimaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: 6.w,
//                   vertical: 6.h,
//                 ),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8.r),
//                   border: Border.all(
//                     color: InvAPColors.kBorderColor,
//                     width: 0.7.w,
//                   ),
//                 ),
//                 child: Row(
//                   spacing: 10.w,
//                   children: [
//                     InkWell(
//                       onTap: () {},
//                       child: Padding(
//                         padding: const EdgeInsets.only(bottom: 8.0),
//                         child: Icon(Icons.minimize, size: 18, ),
//                       ),
//                     ),
//                     Text("1"),
//                     InkWell(
//                       onTap: () {},
//                       child: Icon(Icons.add, size: 18,),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
