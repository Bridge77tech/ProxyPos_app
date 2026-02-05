import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/bloc/dashboard_state.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/widgets/product_container_card.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';

import '../../../../../../core/app_constants/ap_colors.dart';

class APDashboardPage extends StatelessWidget {
  const APDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // Left column - flexible (approx 70%)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 0.2.sh,
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: InvAPColors.kWhiteColor,
                  ),
                  child: Column(children: [

                  ],
                ),
                ),
                Gap(10.h),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color: InvAPColors.kWhiteColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 25.w,
                            vertical: 12.h,
                          ),
                          child: Text(
                            'Most Purchased',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: BlocBuilder<DashboardBloc, DashboardState>(
                            builder: (context, state) {
                              if (state.loading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (state.error != null &&
                                  state.topProducts.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Failed to load top products',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                );
                              }
                              final items = state.topProducts;
                              return GridView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                ),
                                shrinkWrap: true,
                                primary: false,
                                itemCount: items.length,
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 150.w,
                                      mainAxisSpacing: 25.h,
                                      crossAxisSpacing: 25.w,
                                      childAspectRatio: 1,
                                    ),
                                itemBuilder: (context, i) {
                                  final p = items[i];
                                  final v = (p.variants?.isNotEmpty ?? false)
                                      ? p.variants!.first
                                      : null;
                                  return ProductContainerCard(
                                    variants: v,
                                    product: p,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Gap(10.w),

          // Right column - flexible (approx 30%) using flex-based vertical sizing
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Top small card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.r),
                    color: InvAPColors.kWhiteColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        InvAppConstants.kCart,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      InkWell(
                        onTap: () {},
                        child: Image.asset(
                          Assets.iconsDeleteIcon,
                          scale: 4.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Gap(10.h),

                // Middle area: takes majority of remaining vertical space
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: InvAPColors.kWhiteColor,
                    ),
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, item) => Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        width: 1.sw,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: InvAPColors.kBorderColor,
                            width: 0.7.w,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text("#1"),
                                InkWell(
                                  onTap: () {},
                                  child: Image.asset(
                                    Assets.iconsDeleteIcon,
                                    scale: 4.5,
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              endIndent: 0,
                              indent: 0,
                              color: InvAPColors.kBorderColor,
                              thickness: 0.7.w,
                            ),
                            Gap(10.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Nestle Nido Essential",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        "Tin 150g",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: InvAPColors
                                                  .kSecondaryTextColor,
                                            ),
                                      ),
                                      Text(
                                        "${InvAppConstants.kGHC} 100.00",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color:
                                                  InvAPColors.kPrimaryColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: InvAPColors.kBorderColor,
                                      width: 0.7.w,
                                    ),
                                  ),
                                  child: Row(
                                    spacing: 10.w,
                                    children: [
                                      InkWell(
                                        onTap: () {},
                                        child: Icon(Icons.minimize),
                                      ),
                                      Text("1"),
                                      InkWell(
                                        onTap: () {},
                                        child: Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Gap(10.h),

                // Bottom area: smaller area that shares remaining space
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 1.sw,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: InvAPColors.kWhiteColor,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10.h,
                        children: [
                          _rowText(
                            context,
                            label: InvAppConstants.kVAT,
                            value: '${InvAppConstants.kGHC} 100.00',
                          ),
                          _rowText(
                            context,
                            label: InvAppConstants.kDiscount,
                            value: '${InvAppConstants.kGHC} 0.00',
                          ),
                          _rowText(
                            context,
                            label: InvAppConstants.kSubTotal,
                            value: '${InvAppConstants.kGHC} 100.00',
                          ),
                          _rowText(
                            context,
                            label: InvAppConstants.kTotal,
                            value: '${InvAppConstants.kGHC} 100.00',
                            fontWeight: FontWeight.w700,
                          ),
                          ApButton(
                            onPressed: () {},
                            btnText: 'Submit Order',
                            fontSize: 12,
                            height: 40,
                            width: 1.sw,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Gap(10.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowText(
    BuildContext context, {
    required String label,
    required String value,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(fontWeight: fontWeight),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(fontWeight: fontWeight),
        ),
      ],
    );
  }
}
