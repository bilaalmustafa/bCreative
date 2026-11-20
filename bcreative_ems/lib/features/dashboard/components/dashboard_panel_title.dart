import 'package:flutter/material.dart';

/// Heading for a dashboard card.
class DashboardPanelTitle extends StatelessWidget {
  const DashboardPanelTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
  );
}
