import 'dart:async';

import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/notifications/models/app_notification_model.dart';
import 'package:bcreative_ems/features/notifications/repositories/notification_repository.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  NotificationController(this._repository, this._authController);

  final NotificationRepository _repository;
  final AuthController _authController;

  final notifications = <AppNotificationModel>[].obs;
  final isLoading = false.obs;

  StreamSubscription<List<AppNotificationModel>>? _subscription;
  Worker? _sessionWorker;
  bool _receivedInitialSnapshot = false;

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_authController.session, (_) => _listen());
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    notifications.clear();
    _receivedInitialSnapshot = false;

    final session = _authController.session.value;
    if (session == null || !session.isAuthenticated) return;

    final stream = switch (session.role) {
      UserRole.superAdmin => _repository.watchForAdmins(),
      UserRole.employee => _repository.watchForEmployee(
        session.employeeId ?? session.uid,
      ),
      UserRole.unknown => Stream<List<AppNotificationModel>>.value(const []),
    };

    isLoading.value = true;
    _subscription = stream.listen(
      (items) {
        final previousIds = notifications.map((item) => item.id).toSet();
        notifications.assignAll(items);
        isLoading.value = false;

        if (_receivedInitialSnapshot) {
          AppNotificationModel? newestUnread;
          for (final item in items) {
            if (!item.isRead && !previousIds.contains(item.id)) {
              newestUnread = item;
              break;
            }
          }
          if (newestUnread != null) {
            Get.snackbar(
              newestUnread.title,
              newestUnread.body,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 5),
            );
          }
        }
        _receivedInitialSnapshot = true;
      },
      onError: (Object error) {
        isLoading.value = false;
        Get.snackbar('Notifications unavailable', FailureMapper.message(error));
      },
    );
  }

  /// Updates the badge immediately, then lets the Firestore snapshot confirm
  /// the write. Waiting only for the remote snapshot made the badge look stale
  /// while the user had already navigated away from the notification panel.
  Future<void> markRead(AppNotificationModel notification) async {
    if (notification.isRead || notification.id.isEmpty) return;

    _replace(notification.copyWith(isRead: true, readAt: DateTime.now()));
    try {
      await _repository.markRead(notification);
    } catch (error) {
      _replace(notification);
      Get.snackbar('Notification unavailable', FailureMapper.message(error));
    }
  }

  Future<void> markAllRead() async {
    final unread = notifications
        .where((notification) => !notification.isRead)
        .toList(growable: false);
    if (unread.isEmpty) return;

    final readAt = DateTime.now();
    notifications.assignAll([
      for (final notification in notifications)
        notification.isRead
            ? notification
            : notification.copyWith(isRead: true, readAt: readAt),
    ]);

    try {
      await _repository.markAllRead(unread);
    } catch (error) {
      for (final notification in unread) {
        final index = notifications.indexWhere(
          (item) => item.id == notification.id,
        );
        if (index != -1 && notifications[index].isRead) {
          notifications[index] = notification;
        }
      }
      notifications.refresh();
      Get.snackbar('Notifications unavailable', FailureMapper.message(error));
    }
  }

  void _replace(AppNotificationModel notification) {
    final index = notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index == -1) return;
    notifications[index] = notification;
    notifications.refresh();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _sessionWorker?.dispose();
    super.onClose();
  }
}
