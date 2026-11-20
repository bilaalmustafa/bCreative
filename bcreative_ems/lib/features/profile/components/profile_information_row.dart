import 'package:flutter/material.dart';

/// A responsive label/value line in a profile information section.
class ProfileInformationRow extends StatelessWidget {
  const ProfileInformationRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: showDivider
          ? const Border(bottom: BorderSide(color: Color(0xFFE8EDF7)))
          : null,
    ),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF5F76A0), size: 20),
          const SizedBox(width: 11),
        ],
        Expanded(
          flex: icon == null ? 4 : 3,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4F6692),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
