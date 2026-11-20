import 'package:flutter/material.dart';

/// Shared elevated containers used by feature pages.
///
/// Named constructors preserve the existing visual treatments while avoiding
/// page-local copies of the same card decoration.
class AppSurface extends StatelessWidget {
  const AppSurface.workspace({
    super.key,
    required this.child,
    required this.padding,
  }) : _border = const Border.fromBorderSide(
         BorderSide(color: Color(0xFFE8EEF8)),
       ),
       _shadow = const [
         BoxShadow(
           color: Color(0x080F2D66),
           blurRadius: 18,
           offset: Offset(0, 8),
         ),
       ],
       _borderRadius = 12;

  const AppSurface.content({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  }) : _border = null,
       _shadow = const [
         BoxShadow(
           color: Color(0x0A294E85),
           blurRadius: 18,
           offset: Offset(0, 5),
         ),
       ],
       _borderRadius = 12;

  const AppSurface.employeeContent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  }) : _border = null,
       _shadow = const [
         BoxShadow(
           color: Color(0x0A294E85),
           blurRadius: 18,
           offset: Offset(0, 5),
         ),
       ],
       _borderRadius = 13;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Border? _border;
  final List<BoxShadow> _shadow;
  final double _borderRadius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_borderRadius),
      border: _border,
      boxShadow: _shadow,
    ),
    child: child,
  );
}
