import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/l10n/common/app_localizations.dart' as common_l10n;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Safely get l10n, assuming context is valid and delegate is active
    final l10n = common_l10n.CommonLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: l10n.privacyPolicy.text.bold.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            l10n.privacyPriority.text.xl.bold.make(),
            16.heightBox,
            l10n.informationWeCollect.text.lg.bold.make(),
            8.heightBox,
            l10n.informationWeCollectDesc.text.make(),
            20.heightBox,

            l10n.howWeUseInformation.text.lg.bold.make(),
            8.heightBox,
            l10n.howWeUseInformationDesc.text.make(),
            20.heightBox,

            l10n.dataSecurity.text.lg.bold.make(),
            8.heightBox,
            l10n.dataSecurityDesc.text.make(),
            20.heightBox,

            l10n.changesToPolicy.text.lg.bold.make(),
            8.heightBox,
            l10n.changesToPolicyDesc.text.make(),
            40.heightBox,

            l10n.lastUpdated.text.gray400.make().centered(),
          ],
        ),
      ),
    );
  }
}
