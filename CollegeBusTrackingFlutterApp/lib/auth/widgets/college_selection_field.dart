import 'package:flutter/material.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/l10n/signup/auth_signup_localizations.dart';

class CollegeSelectionField extends StatelessWidget {
  final List<CollegeModel> colleges;
  final CollegeModel? selectedCollege;
  final ValueChanged<CollegeModel?> onChanged;
  final bool isLoading;

  const CollegeSelectionField({
    super.key,
    required this.colleges,
    required this.selectedCollege,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = SignupLocalizations.of(context)!;
    return VStack([
      l10n.college.text
          .size(16)
          .medium
          .color(Theme.of(context).colorScheme.onSurface)
          .make(),
      8.heightBox,
      LayoutBuilder(
        builder: (context, constraints) {
          final double dropdownWidth = constraints.maxWidth - 48;

          return isLoading
              ? const CircularProgressIndicator().centered()
              : DropdownButtonFormField<CollegeModel>(
                  isExpanded: true,
                  value: selectedCollege,
                  selectedItemBuilder: (BuildContext context) {
                    return colleges.map<Widget>((CollegeModel college) {
                      return college.name.text
                          .maxLines(1)
                          .ellipsis
                          .color(Theme.of(context).colorScheme.onSurface)
                          .normal
                          .make();
                    }).toList();
                  },
                  items: colleges.map((college) {
                    return DropdownMenuItem(
                      value: college,
                      child: SizedBox(
                        width: dropdownWidth,
                        child: college.name.text.maxLines(1).ellipsis.make(),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: l10n.selectCollege,
                    prefixIcon: const Icon(Icons.school_outlined),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) =>
                      value == null ? l10n.pleaseSelectCollege : null,
                );
        },
      ),
    ]);
  }
}
