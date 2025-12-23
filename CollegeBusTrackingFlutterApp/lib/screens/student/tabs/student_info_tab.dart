import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          const Text(
            'Available Bus Numbers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          if (allBusNumbers.isEmpty)
            const Text('No bus numbers found')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allBusNumbers
                  .map(
                    (busNumber) => Chip(
                      label: Text(busNumber),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  )
                  .toList(),
            ),

          const SizedBox(height: AppSizes.paddingLarge),

          const Text(
            'All Stops',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          if (allStops.isEmpty)
            const Text('No stops found')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allStops.length,
              itemBuilder: (context, index) {
                final stop = allStops[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                  child: ListTile(
                    leading: const Icon(
                      Icons.place,
                      color: AppColors.secondary,
                    ),
                    title: Text(stop),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
