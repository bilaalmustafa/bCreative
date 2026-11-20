import 'package:flutter/material.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE7EDF7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A1B3D70),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

