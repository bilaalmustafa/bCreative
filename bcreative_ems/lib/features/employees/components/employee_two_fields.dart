import 'package:flutter/material.dart';

/// Places two employee form fields side-by-side when there is room.
class EmployeeTwoFields extends StatelessWidget {
  const EmployeeTwoFields({
    super.key,
    required this.first,
    required this.second,
  });

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330) {
          return Column(children: [first, const SizedBox(height: 13), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
