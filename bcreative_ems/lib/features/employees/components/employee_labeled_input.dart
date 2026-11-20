import 'package:bcreative_ems/features/employees/components/employee_field_label.dart';
import 'package:flutter/material.dart';

/// A labelled text field used in employee forms.
class EmployeeLabeledInput extends StatelessWidget {
  const EmployeeLabeledInput({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EmployeeFieldLabel(label),
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(hintText: hint),
        validator: validator,
      ),
    ],
  );
}
