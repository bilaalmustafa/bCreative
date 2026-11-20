import 'package:flutter/material.dart';

/// Standard surface for employee profile sections.
class ProfileSurface extends StatelessWidget {
  const ProfileSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE5ECF8)),
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
