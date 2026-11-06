import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  taskAssigned('task_assigned'),
  projectAssigned('project_assigned'),
  payrollPaid('payroll_paid'),
  taskActivity('task_activity'),
  taskProgress('task_progress'),
  attendanceCheckIn('attendance_check_in'),
  attendanceCheckOut('attendance_check_out');

  const AppNotificationType(this.value);

  final String value;

  static AppNotificationType fromValue(String? value) => values.firstWhere(
    (type) => type.value == value,
    orElse: () => AppNotificationType.taskActivity,
  );
}

enum NotificationRecipientRole {
  employee('employee'),
  admin('admin');

  const NotificationRecipientRole(this.value);

  final String value;

  static NotificationRecipientRole fromValue(String? value) =>
      values.firstWhere(
        (role) => role.value == value,
        orElse: () => NotificationRecipientRole.employee,
      );
}

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.actorId,
    required this.type,
    required this.title,
    required this.body,
    required this.referenceId,
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  /// The shared target id used for notices shown to every Super Admin.
  static const adminRecipientId = 'super_admin';

  final String id;
  final String recipientId;
  final NotificationRecipientRole recipientRole;
  final String actorId;
  final AppNotificationType type;
  final String title;
  final String body;
  final String referenceId;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  AppNotificationModel copyWith({bool? isRead, DateTime? readAt}) =>
      AppNotificationModel(
        id: id,
        recipientId: recipientId,
        recipientRole: recipientRole,
        actorId: actorId,
        type: type,
        title: title,
        body: body,
        referenceId: referenceId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );

  factory AppNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return AppNotificationModel(
      id: document.id,
      recipientId: data['recipientId'] as String? ?? '',
      recipientRole: NotificationRecipientRole.fromValue(
        data['recipientRole'] as String?,
      ),
      actorId: data['actorId'] as String? ?? '',
      type: AppNotificationType.fromValue(data['type'] as String?),
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      referenceId: data['referenceId'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
      readAt: _readDate(data['readAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'recipientId': recipientId,
    'recipientRole': recipientRole.value,
    'actorId': actorId,
    'type': type.value,
    'title': title.trim(),
    'body': body.trim(),
    'referenceId': referenceId,
    'isRead': isRead,
    'createdAt': FieldValue.serverTimestamp(),
    'readAt': null,
  };

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
