import 'package:flutter/material.dart';

/// Empty state displayed inside a dashboard card.
class DashboardEmptyPanel extends StatelessWidget {
  const DashboardEmptyPanel({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Center(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8AA0C7), size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFF6B7F9F))),
        ],
      ),
    ),
  );
}
