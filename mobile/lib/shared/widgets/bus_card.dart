import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/constants/constants.dart';

class BusCard extends StatelessWidget {
  final BusModel bus;
  final RouteModel? route;
  final VoidCallback? onViewLocation;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showLiveStatus;

  const BusCard({
    super.key,
    required this.bus,
    this.route,
    this.onViewLocation,
    this.onTap,
    this.isSelected = false,
    this.showLiveStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: VStack([
          HStack([
            CircleAvatar(
              backgroundColor: isSelected
                  ? AppColors.primary
                  : AppColors.success,
              child: bus.busNumber
                  .replaceAll('Bus ', '')
                  .text
                  .color(Colors.white)
                  .bold
                  .make(),
            ),
            AppSizes.paddingMedium.widthBox,
            VStack([
              'Bus ${bus.busNumber}'.text
                  .size(18)
                  .bold
                  .color(
                    isSelected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurface,
                  )
                  .make(),
              if (route != null)
                VStack([
                  '${route!.startPoint.name} → ${route!.endPoint.name}'.text
                      .size(14)
                      .color(
                        context.colorScheme.onSurface.withValues(alpha: 0.6),
                      )
                      .make(),
                  if (route!.stopPoints.isNotEmpty)
                    'Stops: ${route!.stopPoints.map((s) => s.name).join(', ')}'
                        .text
                        .size(12)
                        .color(
                          context.colorScheme.onSurface.withValues(alpha: 0.6),
                        )
                        .maxLines(2)
                        .ellipsis
                        .make(),
                ]),
            ]).expand(),
            if (showLiveStatus)
              (bus.isActive ? 'Live' : 'Offline').text
                  .color(Colors.white)
                  .size(12)
                  .semiBold
                  .make()
                  .pSymmetric(h: AppSizes.paddingSmall, v: 4)
                  .box
                  .color(bus.isActive ? AppColors.success : AppColors.warning)
                  .roundedExpected(AppSizes.radiusSmall)
                  .make(),
          ]),
          if (onViewLocation != null)
            VStack([
              AppSizes.paddingMedium.heightBox,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewLocation,
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('View Live Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
        ]).p(AppSizes.paddingMedium),
      ),
    );
  }
}

extension on VxBox {
  VxBox roundedExpected(double radius) {
    return rounded.customRounded(BorderRadius.circular(radius));
  }
}
