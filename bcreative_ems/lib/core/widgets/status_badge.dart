import 'package:bcreative_ems/features/employees/models/employment_enums.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final EmploymentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      EmploymentStatus.active => (Colors.green.shade800, Colors.green.shade50),
      EmploymentStatus.inactive => (Colors.grey.shade700, Colors.grey.shade100),
      EmploymentStatus.onLeave => (
        Colors.orange.shade800,
        Colors.orange.shade50,
      ),
      EmploymentStatus.terminated => (Colors.red.shade800, Colors.red.shade50),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
