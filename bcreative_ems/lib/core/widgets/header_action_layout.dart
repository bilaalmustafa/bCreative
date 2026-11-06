import 'package:flutter/material.dart';

/// Keeps a page heading and its primary action aligned on wide screens while
/// preserving a right-aligned action below the heading on compact screens.
class HeaderActionLayout extends StatelessWidget {
  const HeaderActionLayout({
    super.key,
    required this.heading,
    required this.action,
    this.desktopBreakpoint = 850,
  });

  final Widget heading;
  final Widget action;
  final double desktopBreakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= desktopBreakpoint) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            action,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      );
    },
  );
}
