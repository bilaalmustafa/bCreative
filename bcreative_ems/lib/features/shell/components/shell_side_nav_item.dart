import 'package:bcreative_ems/features/shell/viewmodels/shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A sidebar navigation item that replaces the current shell route.
class ShellSideNavItem extends StatelessWidget {
  const ShellSideNavItem({
    super.key,
    required this.item,
    required this.expanded,
  });

  final ShellNavItem item;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final active =
        item.route.isNotEmpty && Get.currentRoute.startsWith(item.route);
    return Tooltip(
      message: item.label,
      child: Material(
        color: active ? const Color(0xFF3975F5) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (item.route.isNotEmpty && !active) {
              Get.offNamed(item.route, preventDuplicates: true);
            } else if (item.route.isEmpty) {
              Get.snackbar(
                'Coming soon',
                '${item.label} is not implemented yet.',
              );
            }
          },
          child: Container(
            height: 49,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: active ? Colors.white : const Color(0xFFE2EAFE),
                  size: 21,
                ),
                if (expanded) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (item.isComingSoon)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB8C8E4),
                      size: 19,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
