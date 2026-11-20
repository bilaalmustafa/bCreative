import 'package:flutter/material.dart';

/// Brand name displayed beside the shell logo.
class ShellBrandText extends StatelessWidget {
  const ShellBrandText({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'B-Creative',
        style: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -.5,
        ),
      ),
      Text(
        'EMS',
        style: TextStyle(
          color: Color(0xFF78A5FF),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
