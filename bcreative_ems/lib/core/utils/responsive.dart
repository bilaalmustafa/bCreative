import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
}

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.desktop) return ScreenSize.desktop;
  if (width >= Breakpoints.tablet) return ScreenSize.tablet;
  return ScreenSize.mobile;
}

bool isDesktop(BuildContext context) =>
    screenSizeOf(context) == ScreenSize.desktop;

bool isMobile(BuildContext context) =>
    screenSizeOf(context) == ScreenSize.mobile;
