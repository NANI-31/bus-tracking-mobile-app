import 'package:flutter/material.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'package:collegebus/shared/widgets/staggered_entrance_widget.dart';

class CoordinatorListLayout<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyState;
  final Future<void> Function()? onRefresh;
  final PageStorageKey<String>? pageStorageKey;
  final double maxTabletWidth;
  final double maxDesktopWidth;
  final ScrollController? scrollController;

  const CoordinatorListLayout({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.emptyState,
    this.onRefresh,
    this.pageStorageKey,
    this.maxTabletWidth = 650.0,
    this.maxDesktopWidth = 1000.0,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyState ?? const SizedBox.shrink();
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    int columns = 1;
    if (screenWidth >= maxDesktopWidth) {
      columns = 3;
    } else if (screenWidth >= maxTabletWidth) {
      columns = 2;
    }

    final int rowCount = (items.length / columns).ceil();

    final listView = ListView.builder(
      key: pageStorageKey,
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
      padding: const EdgeInsets.only(
        left: AppSizes.paddingMedium,
        right: AppSizes.paddingMedium,
        bottom: 16,
        top: 8,
      ),
      itemCount: rowCount + 1,
      itemBuilder: (context, rowIndex) {
        if (rowIndex == rowCount) {
          return const BottomNavSpacer();
        }

        final int startIndex = rowIndex * columns;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(columns, (colIndex) {
            final int itemIndex = startIndex + colIndex;
            if (itemIndex >= items.length) {
              return const Expanded(child: SizedBox.shrink());
            }

            final T item = items[itemIndex];

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: colIndex > 0 ? 6 : 0,
                  right: colIndex < columns - 1 ? 6 : 0,
                ),
                child: StaggeredEntranceWidget(
                  index: itemIndex,
                  child: itemBuilder(context, item, itemIndex),
                ),
              ),
            );
          }),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: AppColors.primary,
        strokeWidth: 3.0,
        onRefresh: onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}
