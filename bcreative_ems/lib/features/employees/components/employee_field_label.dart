import 'package:flutter/material.dart';

/// Label displayed above a field in employee forms.
class EmployeeFieldLabel extends StatelessWidget {
  const EmployeeFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
