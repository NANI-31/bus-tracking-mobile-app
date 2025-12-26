import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/user_model.dart';

class DriverApprovalsTab extends StatelessWidget {
  final List<UserModel> pendingDrivers;
  final Function(UserModel) onApprove;
  final Function(UserModel) onReject;

  const DriverApprovalsTab({
    super.key,
    required this.pendingDrivers,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return pendingDrivers.isEmpty
        ? VStack(
            [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              AppSizes.paddingMedium.heightBox,
              'No pending driver approvals'.text
                  .size(18)
                  .color(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  )
                  .make(),
            ],
            alignment: MainAxisAlignment.center,
            crossAlignment: CrossAxisAlignment.center,
          ).centered()
        : ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: pendingDrivers.length,
            itemBuilder: (context, index) {
              final driver = pendingDrivers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(
                      Icons.drive_eta,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  title: driver.fullName.text.semiBold.make(),
                  subtitle: VStack([
                    driver.email.text.make(),
                    if (driver.phoneNumber != null &&
                        driver.phoneNumber!.isNotEmpty)
                      'Phone: ${driver.phoneNumber}'.text.make(),
                    'Applied: ${driver.createdAt.toString().substring(0, 10)}'
                        .text
                        .size(12)
                        .color(
                          Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        )
                        .make(),
                  ]),
                  trailing: HStack([
                    IconButton(
                      icon: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      onPressed: () => onApprove(driver),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => onReject(driver),
                    ),
                  ]),
                  isThreeLine: true,
                ),
              );
            },
          );
  }
}
