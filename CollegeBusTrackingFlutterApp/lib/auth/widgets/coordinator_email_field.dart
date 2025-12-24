import 'package:flutter/material.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:velocity_x/velocity_x.dart';

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
    return HStack([
      CustomInputField(
        label: 'Email ID',
        hint: 'e.g. john.doe',
        controller: idController,
        prefixIcon: const Icon(Icons.email_outlined),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Enter email id' : null,
      ).expand(),
      8.widthBox,
      CustomInputField(
        label: 'Domain',
        hint: 'e.g. rvrjc.ac.in',
        controller: domainController,
        prefixIcon: const Icon(Icons.alternate_email),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Enter domain';
          }
          if (!value.contains('.')) {
            return 'Invalid domain';
          }
          return null;
        },
      ).expand(),
    ]);
  }
}
