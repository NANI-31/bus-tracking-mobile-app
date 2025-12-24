import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class TrackBusButton extends StatelessWidget {
  final VoidCallback onTap;

  const TrackBusButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: HStack([
          const Icon(Icons.near_me_rounded, color: Colors.white, size: 24),
          12.widthBox,
          "Track Bus Live".text.white.xl.bold.make(),
        ]),
      ),
    ).onTap(onTap);
  }
}
