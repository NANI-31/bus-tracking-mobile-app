import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/l10n/common/app_localizations.dart' as common_l10n;

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Safely get l10n, assuming context is valid and delegate is active
    final l10n = common_l10n.CommonLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: l10n.termsConditions.text.bold.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            l10n.termsOfService.text.xl.bold.make(),
            16.heightBox,
            l10n.agreementToTerms.text.lg.bold.make(),
            8.heightBox,
            l10n.agreementToTermsDesc.text.make(),
            20.heightBox,

            l10n.userResponsibility.text.lg.bold.make(),
            8.heightBox,
            l10n.userResponsibilityDesc.text.make(),
            20.heightBox,

            l10n.serviceAvailability.text.lg.bold.make(),
            8.heightBox,
            l10n.serviceAvailabilityDesc.text.make(),
            20.heightBox,

            l10n.governingLaw.text.lg.bold.make(),
            8.heightBox,
            l10n.governingLawDesc.text.make(),
            40.heightBox,

            l10n.lastUpdated.text.gray400.make().centered(),
          ],
        ),
      ),
    );
  }
}
