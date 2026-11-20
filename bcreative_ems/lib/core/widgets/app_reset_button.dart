import 'package:flutter/material.dart';

/// A consistent, compact reset action for filters and detail panels.
class AppResetButton extends StatelessWidget {
  const AppResetButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Reset filters',
    this.size = 40,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox.square(
      dimension: size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.square(size),
          maximumSize: Size.square(size),
          foregroundColor: const Color(0xFF596577),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF7B8492)),
          shape: const CircleBorder(),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: const Icon(Icons.refresh_rounded, size: 23),
      ),
    ),
  );
}
