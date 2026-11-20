import 'package:flutter/material.dart';

/// Warning displayed when a live dashboard source is unavailable.
class DashboardDataWarning extends StatelessWidget {
  const DashboardDataWarning({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4DD),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFD88C)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFFAD7000)),
        const SizedBox(width: 9),
        Expanded(
          child: Text('Some live dashboard data is unavailable: $message'),
        ),
      ],
    ),
  );
}
