import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/presentation/bloc/history_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/presentation/bloc/history_event.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/presentation/bloc/history_state.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/presentation/widgets/transaction_card.dart';

class APHistoryPage extends StatefulWidget {
  const APHistoryPage({super.key});

  @override
  State<APHistoryPage> createState() => _APHistoryPageState();
}

class _APHistoryPageState extends State<APHistoryPage> {
  final _searchController = TextEditingController();
  final _searchDebounce = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const LoadHistory());
    _searchDebounce.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<HistoryBloc>().add(SearchHistory(_searchDebounce.value));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce.removeListener(_onSearchChanged);
    _searchDebounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap(16.h),

          // Search bar
          Center(
            child: SizedBox(
              width: 500.w,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _searchDebounce.value = val,
                decoration: InputDecoration(
                  hintText: 'Search by sale ID',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: InvAPColors.kSecondaryTextColor,
                      ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: InvAPColors.kSecondaryTextColor,
                    size: 20.sp,
                  ),
                  filled: true,
                  fillColor: InvAPColors.kWhiteColor,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide: BorderSide(
                      color: InvAPColors.kPrimaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Gap(16.h),

          // Transaction list
          Expanded(
            child: BlocBuilder<HistoryBloc, HistoryState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: InvAPColors.kPrimaryColor,
                    ),
                  );
                }

                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48.sp,
                          color: InvAPColors.kSecondaryTextColor,
                        ),
                        Gap(12.h),
                        Text(
                          state.error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: InvAPColors.kSecondaryTextColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        Gap(16.h),
                        TextButton(
                          onPressed: () =>
                              context.read<HistoryBloc>().add(const RefreshHistory()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state.sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 56.sp,
                          color: InvAPColors.kBorderColor,
                        ),
                        Gap(12.h),
                        Text(
                          'No transactions found',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: InvAPColors.kSecondaryTextColor,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.only(bottom: 20.h),
                  itemCount: state.sales.length,
                  separatorBuilder: (context, index) => Gap(10.h),
                  itemBuilder: (context, index) {
                    return TransactionCard(sale: state.sales[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
