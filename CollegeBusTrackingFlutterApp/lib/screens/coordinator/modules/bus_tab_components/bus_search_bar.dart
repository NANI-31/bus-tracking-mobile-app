import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';

class BusSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final String searchQuery;
  final String hintText;

  final FocusNode focusNode;

  const BusSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.searchQuery,
    this.hintText = 'Search...',
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
          controller: controller,
          onChanged: onChanged,
          focusNode: focusNode,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 28,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
                : null,
          ),
        )
        .pSymmetric(h: 16, v: 0)
        .box
        .color(context.cardColor)
        .withRounded(value: 35)
        .shadowSm
        .border(color: Colors.grey.withValues(alpha: 0.2))
        .make()
        .pOnly(left: 16, right: 16, top: 16, bottom: 12);
  }
}
