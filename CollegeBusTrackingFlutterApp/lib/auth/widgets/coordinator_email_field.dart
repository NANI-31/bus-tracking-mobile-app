import 'package:flutter/material.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/l10n/auth/signup/auth_signup_localizations.dart';

class CoordinatorEmailField extends StatelessWidget {
  final TextEditingController idController;
  final TextEditingController domainController;

  const CoordinatorEmailField({
    super.key,
    required this.idController,
    required this.domainController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = SignupLocalizations.of(context)!;
    return HStack([
      CustomInputField(
        label: l10n.emailId,
        hint: 'e.g. john.doe',
        controller: idController,
        prefixIcon: const Icon(Icons.email_outlined),
        validator: (value) =>
            (value == null || value.isEmpty) ? l10n.enterEmailId : null,
      ).expand(),
      8.widthBox,
      CustomInputField(
        label: l10n.domain,
        hint: 'e.g. rvrjc.ac.in',
        controller: domainController,
        prefixIcon: const Icon(Icons.alternate_email),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.enterDomain;
          }
          if (!value.contains('.')) {
            return l10n.invalidDomain;
          }
          return null;
        },
      ).expand(),
    ]);
  }
}
