import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:flutter/material.dart';

/// Compact page context shown below the app bar.
///
/// The page title belongs to [AppShell]'s app bar. This keeps only the visual
/// cue and supporting description, which stays on one line on every screen.
class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.icon,
    required this.description,
    this.iconColor = const Color(0xFF2468F2),
    this.backgroundColor = const Color(0xFFE7F0FF),
    this.boxSize = 47,
    this.iconSize = 27,
    this.borderRadius = 14,
  });

  final IconData icon;
  final String description;
  final Color iconColor;
  final Color backgroundColor;
  final double boxSize;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final compact = isMobile(context);
    final size = compact ? boxSize - 3 : boxSize;

    return Row(
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(
              compact ? borderRadius - 2 : borderRadius,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: compact ? iconSize - 2 : iconSize,
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF60749A),
              fontSize: compact ? 12 : 13,
            ),
          ),
        ),
      ],
    );
  }
}
