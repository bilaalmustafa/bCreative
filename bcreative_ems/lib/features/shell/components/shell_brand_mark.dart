import 'package:flutter/material.dart';

/// Brand artwork for the application navigation shell.
class ShellBrandMark extends StatelessWidget {
  const ShellBrandMark({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 30.0 : 80.0;
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        'assets/branding/bcreative_logo_white.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'B-Creative',
      ),
    );
  }
}
