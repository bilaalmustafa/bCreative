import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/notifications/models/app_notification_model.dart';
import 'package:bcreative_ems/features/notifications/viewmodels/notification_controller.dart';
import 'package:bcreative_ems/features/profile/models/employee_profile_model.dart';
import 'package:bcreative_ems/features/profile/repositories/employee_profile_repository.dart';
import 'package:bcreative_ems/features/shell/viewmodels/shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppShell extends GetView<ShellController> {
  const AppShell({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isAdmin = auth.role.isSuperAdmin;

    if (!isDesktop(context)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            const _NotificationButton(),
            _UserMenu(auth: auth, compact: true),
          ],
        ),
        drawer: _AppDrawer(isAdmin: isAdmin, auth: auth),
        body: body,
      );
    }

    return Obx(
      () => Scaffold(
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: controller.sidebarExpanded.value ? 266 : 78,
              child: _SideBar(
                expanded: controller.sidebarExpanded.value,
                isAdmin: isAdmin,
                onToggle: controller.toggleSidebar,
                auth: auth,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(title: title, auth: auth),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.auth});

  final String title;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1200;
    return Material(
      color: Colors.white,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE8EDF6))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1E355E),
                  fontSize: compact ? 18 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const _NotificationButton(),
            const SizedBox(width: 12),
            _UserMenu(auth: auth),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatefulWidget {
  const _NotificationButton();

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  final _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final notifications = Get.find<NotificationController>();
    return Obx(() {
      final unread = notifications.unreadCount;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            key: _anchorKey,
            tooltip: 'Notifications',
            onPressed: () => _showNotifications(context, notifications),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF29456F),
              size: 27,
            ),
          ),
          if (unread > 0)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                constraints: const BoxConstraints(minHeight: 17, minWidth: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4B57),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  void _showNotifications(
    BuildContext context,
    NotificationController controller,
  ) {
    final anchorContext = _anchorKey.currentContext;
    final navigator = Navigator.of(context);
    final overlay = navigator.overlay;
    if (anchorContext == null || overlay == null) return;

    final anchorBox = anchorContext.findRenderObject();
    final overlayBox = overlay.context.findRenderObject();
    if (anchorBox is! RenderBox ||
        overlayBox is! RenderBox ||
        !anchorBox.hasSize) {
      return;
    }

    final anchorOffset = anchorBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final anchor = anchorOffset & anchorBox.size;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss notifications',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (dialogContext, _, _) {
        final viewport = MediaQuery.sizeOf(dialogContext);
        final panelWidth = viewport.width >= 400 ? 380.0 : viewport.width - 16;
        final left = (anchor.right - panelWidth)
            .clamp(8.0, viewport.width - panelWidth - 8)
            .toDouble();
        final availableHeight = viewport.height - anchor.bottom - 8;
        final panelHeight = availableHeight.clamp(0.0, 460.0).toDouble();

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              if (panelHeight > 0)
                Positioned(
                  left: left,
                  top: anchor.bottom + 8,
                  child: _NotificationsDropdown(
                    controller: controller,
                    width: panelWidth,
                    height: panelHeight,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationsDropdown extends StatelessWidget {
  const _NotificationsDropdown({
    required this.controller,
    required this.width,
    required this.height,
  });

  final NotificationController controller;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 14,
    shadowColor: const Color(0x3329456F),
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: width,
      height: height,
      child: Obx(() {
        final notifications = controller.notifications;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (controller.unreadCount > 0)
                    TextButton(
                      onPressed: controller.markAllRead,
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notifications.isEmpty
                  ? const _EmptyNotifications()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 70),
                      itemBuilder: (context, index) => _NotificationTile(
                        notification: notifications[index],
                        controller: controller,
                        onDismiss: () => Navigator.of(context).pop(),
                      ),
                    ),
            ),
          ],
        );
      }),
    ),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.notifications_off_outlined,
          color: Color(0xFF8091B0),
          size: 38,
        ),
        SizedBox(height: 10),
        Text(
          'You are all caught up.',
          style: TextStyle(color: Color(0xFF526B9A)),
        ),
      ],
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.controller,
    required this.onDismiss,
  });

  final AppNotificationModel notification;
  final NotificationController controller;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return Material(
      color: isUnread ? const Color(0xFFF5F8FF) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _notificationColor(notification.type)
              .withValues(alpha: .12),
          child: Icon(
            _notificationIcon(notification.type),
            color: _notificationColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _notificationTime(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: Color(0xFF7183A5)),
            ),
          ],
        ),
        trailing: isUnread
            ? const Icon(Icons.circle, color: Color(0xFF2468F2), size: 10)
            : null,
        onTap: () {
          controller.markRead(notification);
          onDismiss();
          final route = _notificationRoute(notification.type);
          if (route != null && Get.currentRoute != route) Get.toNamed(route);
        },
      ),
    );
  }
}

IconData _notificationIcon(AppNotificationType type) => switch (type) {
  AppNotificationType.taskAssigned => Icons.assignment_outlined,
  AppNotificationType.projectAssigned => Icons.folder_shared_outlined,
  AppNotificationType.payrollPaid => Icons.payments_outlined,
  AppNotificationType.taskActivity ||
  AppNotificationType.taskProgress => Icons.task_alt_outlined,
  AppNotificationType.attendanceCheckIn ||
  AppNotificationType.attendanceCheckOut => Icons.access_time_rounded,
};

Color _notificationColor(AppNotificationType type) => switch (type) {
  AppNotificationType.taskAssigned ||
  AppNotificationType.taskActivity ||
  AppNotificationType.taskProgress => const Color(0xFF2468F2),
  AppNotificationType.projectAssigned => const Color(0xFF8B5CF6),
  AppNotificationType.payrollPaid => const Color(0xFF10B979),
  AppNotificationType.attendanceCheckIn ||
  AppNotificationType.attendanceCheckOut => const Color(0xFFFF8A13),
};

String? _notificationRoute(AppNotificationType type) => switch (type) {
  AppNotificationType.taskAssigned => AppRoutes.employeeTasks,
  AppNotificationType.projectAssigned => AppRoutes.employeeProjects,
  AppNotificationType.payrollPaid => AppRoutes.employeeSalary,
  AppNotificationType.taskActivity ||
  AppNotificationType.taskProgress => AppRoutes.adminTasks,
  AppNotificationType.attendanceCheckIn ||
  AppNotificationType.attendanceCheckOut => AppRoutes.adminAttendance,
};

String _notificationTime(DateTime? value) {
  if (value == null) return 'Just now';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _UserMenu extends StatelessWidget {
  _UserMenu({required this.auth, this.compact = false});

  final AuthController auth;
  final bool compact;
  final EmployeeProfileRepository _profileRepository =
      EmployeeProfileRepository();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = auth.session.value;
      final email = session?.email?.trim() ?? '';
      final employeeId = session?.employeeId?.trim().isNotEmpty == true
          ? session!.employeeId!.trim()
          : session?.uid ?? '';

      if (session?.role != UserRole.employee || employeeId.isEmpty) {
        return _menuFor(name: 'Admin', email: email, photoUrl: null);
      }

      return StreamBuilder<EmployeeProfileModel?>(
        stream: _profileRepository.watchProfile(employeeId),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final profileName = profile?.fullName.trim();
          final profileEmail = profile?.email.trim();
          return _menuFor(
            name: profileName?.isNotEmpty == true
                ? profileName!
                : _nameFromEmail(email),
            email: profileEmail?.isNotEmpty == true ? profileEmail! : email,
            photoUrl: profile?.displayPhotoUrl,
          );
        },
      );
    });
  }

  Widget _menuFor({
    required String name,
    required String email,
    required String? photoUrl,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Account menu',
      offset: const Offset(0, 50),
      onSelected: (value) {
        if (value == 'logout') auth.signOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(email, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Sign out')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AccountAvatar(name: name, photoUrl: photoUrl),
            if (!compact) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 168,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isEmpty ? 'No email address' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6C80A4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF5B7199),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _nameFromEmail(String email) {
    final raw = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .trim();
    if (raw.isEmpty) return 'Admin';
    return raw
        .split(' ')
        .where((item) => item.isNotEmpty)
        .map((item) => '${item[0].toUpperCase()}${item.substring(1)}')
        .join(' ');
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl?.isNotEmpty == true;
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFE7EEFF),
      foregroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              _initials(name),
              style: const TextStyle(
                color: Color(0xFF336BE9),
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  String _initials(String value) {
    final pieces = value.split(' ').where((item) => item.isNotEmpty).take(2);
    final initials = pieces.map((item) => item[0]).join();
    return initials.isEmpty ? 'A' : initials;
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({
    required this.expanded,
    required this.isAdmin,
    required this.onToggle,
    required this.auth,
  });

  final bool expanded;
  final bool isAdmin;
  final VoidCallback onToggle;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final items = isAdmin ? _adminItems : _employeeItems;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The AnimatedContainer changes width over several frames. During that
        // animation, use the actual width rather than the target state so a
        // full header/menu is never laid out inside the narrow sidebar.
        final showLabels = expanded && constraints.maxWidth >= 220;
        final compactHeader = !showLabels;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF101D38), Color(0xFF182A4B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            right: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compactHeader ? 10 : 16,
                    13,
                    10,
                    16,
                  ),
                  child: Row(
                    mainAxisAlignment: compactHeader
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.start,
                    children: [
                      _BrandMark(small: compactHeader),
                      if (showLabels) ...[
                        const SizedBox(width: 10),
                        const Expanded(child: _BrandText()),
                      ],
                      IconButton(
                        tooltip: expanded ? 'Collapse menu' : 'Expand menu',
                        onPressed: onToggle,
                        padding: EdgeInsets.zero,
                        visualDensity: compactHeader
                            ? VisualDensity.compact
                            : VisualDensity.standard,
                        constraints: BoxConstraints.tightFor(
                          width: compactHeader ? 30 : 48,
                          height: compactHeader ? 30 : 48,
                        ),
                        icon: Icon(
                          expanded
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          color: Colors.white70,
                          size: compactHeader ? 20 : 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) =>
                        _SideNavItem(item: items[index], expanded: showLabels),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                  child: showLabels
                      ? const Row(
                          children: [
                            _BrandMark(small: true),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'B-Creative',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'EMS · Version 1.0.1',
                                  style: TextStyle(
                                    color: Color(0xFF94A7C8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const Center(child: _BrandMark(small: true)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.small = false});

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

class _BrandText extends StatelessWidget {
  const _BrandText();

  @override
  Widget build(BuildContext context) {
    return const Column(
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
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({required this.item, required this.expanded});

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
            if (item.route.isNotEmpty) {
              Get.toNamed(item.route);
            } else {
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

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.isAdmin, required this.auth});

  final bool isAdmin;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final items = isAdmin ? _adminItems : _employeeItems;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF14233F)),
            child: Row(
              children: [
                const _BrandMark(),
                const SizedBox(width: 12),
                const _BrandText(),
              ],
            ),
          ),
          ...items.map(
            (item) => ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              trailing: item.isComingSoon
                  ? const Icon(Icons.chevron_right_rounded)
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (item.route.isNotEmpty) {
                  Get.toNamed(item.route);
                } else {
                  Get.snackbar(
                    'Coming soon',
                    '${item.label} is not implemented yet.',
                  );
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: auth.signOut,
          ),
        ],
      ),
    );
  }
}

final _adminItems = [
  const ShellNavItem(
    label: 'Dashboard',
    icon: Icons.grid_view_rounded,
    route: AppRoutes.adminDashboard,
  ),
  const ShellNavItem(
    label: 'Employees',
    icon: Icons.people_alt_outlined,
    route: AppRoutes.adminEmployees,
  ),
  const ShellNavItem(
    label: 'Attendance',
    icon: Icons.calendar_month_outlined,
    route: AppRoutes.adminAttendance,
  ),
  const ShellNavItem(
    label: 'Payroll',
    icon: Icons.account_balance_wallet_outlined,
    route: AppRoutes.adminPayroll,
  ),
  const ShellNavItem(
    label: 'Projects',
    icon: Icons.work_outline_rounded,
    route: AppRoutes.adminProjects,
  ),
  const ShellNavItem(
    label: 'Tasks',
    icon: Icons.fact_check_outlined,
    route: AppRoutes.adminTasks,
  ),
];

final _employeeItems = [
  const ShellNavItem(
    label: 'Dashboard',
    icon: Icons.grid_view_rounded,
    route: AppRoutes.employeeDashboard,
  ),
  const ShellNavItem(
    label: 'My Profile',
    icon: Icons.person_outline_rounded,
    route: AppRoutes.employeeProfile,
  ),
  const ShellNavItem(
    label: 'My Projects',
    icon: Icons.work_outline_rounded,
    route: AppRoutes.employeeProjects,
  ),
  const ShellNavItem(
    label: 'My Tasks',
    icon: Icons.fact_check_outlined,
    route: AppRoutes.employeeTasks,
  ),
  const ShellNavItem(
    label: 'My Attendance',
    icon: Icons.calendar_month_outlined,
    route: AppRoutes.employeeAttendance,
  ),
  const ShellNavItem(
    label: 'My Salary',
    icon: Icons.account_balance_wallet_outlined,
    route: AppRoutes.employeeSalary,
  ),
];
