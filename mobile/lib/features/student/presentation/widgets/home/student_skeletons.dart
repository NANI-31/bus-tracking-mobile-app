import 'package:flutter/material.dart';
import 'package:collegebus/shared/widgets/shimmer_loading.dart';

class StudentHomeSkeleton extends StatelessWidget {
  const StudentHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Welcome Greeting Skeleton Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 120, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 180, height: 28),
                  ],
                ),
                const SkeletonBox.circle(size: 52),
              ],
            ),
            const SizedBox(height: 24),

            // Premium Status skeleton (simulate spacing if active)
            const SkeletonBox(width: 160, height: 36, borderRadius: 18),
            const SizedBox(height: 24),

            // Bus Status Card Skeleton
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(width: 110, height: 10),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              SkeletonBox.circle(size: 20),
                              SizedBox(width: 8),
                              SkeletonBox(width: 80, height: 20),
                            ],
                          ),
                        ],
                      ),
                      const SkeletonBox(width: 90, height: 28, borderRadius: 14),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(width: 130, height: 10),
                          SizedBox(height: 8),
                          SkeletonBox(width: 150, height: 20),
                        ],
                      ),
                      const SkeletonBox(width: 60, height: 24, borderRadius: 10),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Route Card Skeleton
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(width: 100, height: 10),
                          SizedBox(height: 8),
                          SkeletonBox(width: 140, height: 22),
                        ],
                      ),
                      const SkeletonBox(width: 70, height: 30, borderRadius: 10),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Timeline items skeleton
                  ...List.generate(3, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const SkeletonBox.circle(size: 32),
                            if (index < 2) ...[
                              const SizedBox(height: 4),
                              Container(width: 2, height: 36, color: Colors.grey[300]),
                            ],
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              SkeletonBox(width: 70, height: 10),
                              SizedBox(height: 6),
                              SkeletonBox(width: 150, height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Track Button Skeleton
            const SkeletonBox(width: double.infinity, height: 60, borderRadius: 18),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class StudentBusStopSkeleton extends StatelessWidget {
  const StudentBusStopSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 200, height: 24),
                const SizedBox(height: 8),
                const SkeletonBox(width: 280, height: 14),
                const SizedBox(height: 24),
              ],
            );
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                const SkeletonBox(width: 48, height: 48, borderRadius: 12),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 150, height: 16),
                      const SizedBox(height: 8),
                      const SkeletonBox(width: 100, height: 12),
                    ],
                  ),
                ),
                const SkeletonBox.circle(size: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BusScheduleSkeleton extends StatelessWidget {
  const BusScheduleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Tabs Row
            Row(
              children: [
                Expanded(child: const SkeletonBox(height: 48, borderRadius: 24)),
                const SizedBox(width: 12),
                Expanded(child: const SkeletonBox(height: 48, borderRadius: 24)),
              ],
            ),
            const SizedBox(height: 24),
            // Header
            const SkeletonBox(width: 180, height: 20),
            const SizedBox(height: 16),
            // Schedule Items
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SkeletonBox(width: 52, height: 52, borderRadius: 12),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SkeletonBox(width: 120, height: 16),
                              const SizedBox(height: 8),
                              const SkeletonBox(width: 80, height: 12),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SkeletonBox(width: 60, height: 14),
                            const SizedBox(height: 6),
                            const SkeletonBox(width: 40, height: 10),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
