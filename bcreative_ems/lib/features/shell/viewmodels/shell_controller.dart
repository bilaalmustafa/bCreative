import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShellNavItem {
  const ShellNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  bool get isComingSoon => route.isEmpty;
}

class ShellController extends GetxController {
  final RxBool sidebarExpanded = true.obs;
  final RxInt selectedIndex = 0.obs;

  void toggleSidebar() => sidebarExpanded.value = !sidebarExpanded.value;

  void selectIndex(int index) => selectedIndex.value = index;
}
