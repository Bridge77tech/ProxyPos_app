import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/product_container_card.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../../data/model/product_model.dart';
import '../../data/model/variant.dart';
import '../../presentation/bloc/dashboard_bloc.dart';
import '../../presentation/bloc/dashboard_event.dart';
import '../../presentation/bloc/dashboard_state.dart';

class LeftSideDashboardViewCard extends StatelessWidget {
  const LeftSideDashboardViewCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  child: BlocConsumer<DashboardBloc, DashboardState>(
                    listenWhen: (previous, current) {
                      // Keep listener minimal; initial dispatch handled in builder
                      return false;
                    },
                    listener: (context, state) {},
                    builder: (context, state) {
                      // Initial one-time dispatch to load top products
                      if (!state.requested) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          context.read<DashboardBloc>().add(const LoadTopProducts());
                        });
                      }

                      if (state.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Always display topProducts here, ignore search.
                      final List<Products> source = state.topProducts;

                      if (source.isEmpty) {
                        return Center(
                          child: Text(
                            'No products found',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }

                      // Build a flat list of (product, variant) entries so all variants are displayed
                      final List<({Products product, Variants variant})> items = [];
                      for (final p in source) {
                        final vars = p.variants ?? const [];
                        for (final v in vars) {
                          items.add((product: p, variant: v));
                        }
                      }

                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No variants available',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        shrinkWrap: true,
                        primary: false,
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150.w,
                          mainAxisSpacing: 25.h,
                          crossAxisSpacing: 25.w,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, i) {
                          final entry = items[i];
                          return ProductContainerCard(
                            product: entry.product,
                            variants: entry.variant,
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
    );
  }
}
