import 'package:bcreative_ems/features/notifications/models/app_notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Stream<List<AppNotificationModel>> watchForEmployee(String employeeId) {
    if (employeeId.isEmpty) return Stream.value(const []);
    return _notifications
        .where('recipientId', isEqualTo: employeeId)
        .where(
          'recipientRole',
          isEqualTo: NotificationRecipientRole.employee.value,
        )
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotificationModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<AppNotificationModel>> watchForAdmins() => _notifications
      .where('recipientRole', isEqualTo: NotificationRecipientRole.admin.value)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(AppNotificationModel.fromFirestore)
            .toList(growable: false),
      );

  DocumentReference<Map<String, dynamic>> newDocument() => _notifications.doc();

  AppNotificationModel employeeNotification({
    required String employeeId,
    required String actorId,
    required AppNotificationType type,
    required String title,
    required String body,
    required String referenceId,
    String? id,
  }) => AppNotificationModel(
    id: id ?? '',
    recipientId: employeeId,
    recipientRole: NotificationRecipientRole.employee,
    actorId: actorId,
    type: type,
    title: title,
    body: body,
    referenceId: referenceId,
  );

  AppNotificationModel adminNotification({
    required String actorId,
    required AppNotificationType type,
    required String title,
    required String body,
    required String referenceId,
    String? id,
  }) => AppNotificationModel(
    id: id ?? '',
    recipientId: AppNotificationModel.adminRecipientId,
    recipientRole: NotificationRecipientRole.admin,
    actorId: actorId,
    type: type,
    title: title,
    body: body,
    referenceId: referenceId,
  );

  void addEmployeeNotification(
    WriteBatch batch, {
    required String employeeId,
    required String actorId,
    required AppNotificationType type,
    required String title,
    required String body,
    required String referenceId,
  }) {
    final document = newDocument();
    batch.set(
      document,
      employeeNotification(
        id: document.id,
        employeeId: employeeId,
        actorId: actorId,
        type: type,
        title: title,
        body: body,
        referenceId: referenceId,
      ).toJson(),
    );
  }

  void addAdminNotification(
    WriteBatch batch, {
    required String actorId,
    required AppNotificationType type,
    required String title,
    required String body,
    required String referenceId,
  }) {
    final document = newDocument();
    batch.set(
      document,
      adminNotification(
        id: document.id,
        actorId: actorId,
        type: type,
        title: title,
        body: body,
        referenceId: referenceId,
      ).toJson(),
    );
  }

  Future<void> notifyEmployee({
    required String employeeId,
    required String actorId,
    required AppNotificationType type,
    required String title,
    required String body,
    required String referenceId,
  }) {
    final document = newDocument();
    return document.set(
      employeeNotification(
        id: document.id,
        employeeId: employeeId,
        actorId: actorId,
        type: type,
        title: title,
        body: body,
        referenceId: referenceId,
      ).toJson(),
    );
  }

  Future<void> markRead(AppNotificationModel notification) {
    if (notification.isRead || notification.id.isEmpty) return Future.value();
    return _notifications.doc(notification.id).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllRead(Iterable<AppNotificationModel> notifications) async {
    final unread = notifications.where(
      (notification) => !notification.isRead && notification.id.isNotEmpty,
    );
    if (unread.isEmpty) return;
    final batch = _firestore.batch();
    for (final notification in unread) {
      batch.update(_notifications.doc(notification.id), {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
