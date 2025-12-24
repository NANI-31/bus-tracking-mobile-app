import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class StudentInfoTab extends StatelessWidget {
  final List<String> allBusNumbers;
  final List<String> allStops;

  const StudentInfoTab({
    super.key,
    required this.allBusNumbers,
    required this.allStops,
  });

  @override
  Widget build(BuildContext context) {
    return VStack([
      'Information'.text.size(24).bold.make(),
      AppSizes.paddingLarge.heightBox,

      'Available Bus Numbers'.text.size(18).bold.make(),
      AppSizes.paddingMedium.heightBox,

      if (allBusNumbers.isEmpty)
        'No bus numbers found'.text.make()
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allBusNumbers
              .map(
                (busNumber) => Chip(
                  label: Text(busNumber),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                ),
              )
              .toList(),
        ),

      AppSizes.paddingLarge.heightBox,

      'All Stops'.text.size(18).bold.make(),
      AppSizes.paddingMedium.heightBox,

      if (allStops.isEmpty)
        'No stops found'.text.make()
      else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allStops.length,
          itemBuilder: (context, index) {
            final stop = allStops[index];
            return VxBox(
                  child: ListTile(
                    leading: Icon(
                      Icons.place,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(stop),
                  ),
                )
                .color(Theme.of(context).colorScheme.surface)
                .rounded
                .withShadow([
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ])
                .make()
                .pOnly(bottom: AppSizes.paddingSmall);
          },
        ),
    ]).p(AppSizes.paddingMedium).scrollVertical();
  }
}
