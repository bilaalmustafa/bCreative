import 'package:bcreative_ems/features/auth/models/user_access_model.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/employees/models/employment_enums.dart';
import 'package:bcreative_ems/features/notifications/models/app_notification_model.dart';
import 'package:bcreative_ems/features/profile/models/employee_profile_model.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EmployeeModel serializes and deserializes Firestore fields', () {
    final joinedAt = DateTime.utc(2026, 1, 15);
    const employee = EmployeeModel(
      id: 'employee-1',
      employeeCode: 'EMP-0001',
      fullName: 'Ayesha Khan',
      email: 'AYESHA@EXAMPLE.COM',
      department: 'Design',
      employmentStatus: EmploymentStatus.onLeave,
      employmentType: EmploymentType.fullTime,
      salary: 5000,
      bankDetails: EmployeeBankDetails(bankName: 'Example Bank'),
    );

    final json = employee.toJson(includeUpdatedAt: false)
      ..['joiningDate'] = Timestamp.fromDate(joinedAt)
      ..['id'] = employee.id;
    final restored = EmployeeModel.fromJson(json);

    expect(restored.id, employee.id);
    expect(restored.email, 'ayesha@example.com');
    expect(restored.employmentStatus, EmploymentStatus.onLeave);
    expect(restored.bankDetails.bankName, 'Example Bank');
    expect(restored.joiningDate?.toUtc(), joinedAt);
  });

  test('EmployeeProfileModel keeps only employee-safe update fields', () {
    const profile = EmployeeProfileModel(
      id: 'employee-1',
      fullName: 'Ayesha Khan',
      email: 'ayesha@example.com',
      department: 'Design',
      contactNumber: '+966500000000',
    );

    final update = profile.toSelfServiceJson();

    expect(
      update.keys,
      containsAll(<String>[
        'contactNumber',
        'nationality',
        'residentialAddress',
        'updatedAt',
      ]),
    );
    expect(update, isNot(contains('department')));
  });

  test('UserAccessModel stores the employee role without password data', () {
    const access = UserAccessModel(
      id: 'employee-1',
      role: 'employee',
      employeeId: 'employee-1',
      email: 'EMPLOYEE@EXAMPLE.COM',
      isActive: true,
    );

    final json = access.toJson();

    expect(json['email'], 'employee@example.com');
    expect(json['isActive'], isTrue);
    expect(json.containsKey('password'), isFalse);
  });

  test('AppNotificationModel keeps its private delivery target and state', () {
    const notification = AppNotificationModel(
      id: 'notification-1',
      recipientId: 'employee-1',
      recipientRole: NotificationRecipientRole.employee,
      actorId: 'admin-1',
      type: AppNotificationType.taskAssigned,
      title: 'New task assigned',
      body: 'You have been assigned a task.',
      referenceId: 'task-1',
    );

    final json = notification.toJson();

    expect(json['recipientId'], 'employee-1');
    expect(json['recipientRole'], 'employee');
    expect(json['type'], 'task_assigned');
    expect(json['isRead'], isFalse);
    expect(json['readAt'], isNull);
  });

  test(
    'AppNotificationModel copyWith preserves delivery details when read',
    () {
      const notification = AppNotificationModel(
        id: 'notification-1',
        recipientId: 'employee-1',
        recipientRole: NotificationRecipientRole.employee,
        actorId: 'admin-1',
        type: AppNotificationType.taskAssigned,
        title: 'New task assigned',
        body: 'You have been assigned a task.',
        referenceId: 'task-1',
      );
      final readAt = DateTime.utc(2026, 11, 6, 12);

      final read = notification.copyWith(isRead: true, readAt: readAt);

      expect(read.isRead, isTrue);
      expect(read.readAt, readAt);
      expect(read.recipientId, notification.recipientId);
      expect(read.referenceId, notification.referenceId);
    },
  );

  test('EmployeeTaskModel serializes assignment fields', () {
    final dueDate = DateTime.utc(2026, 4, 1);
    final task = EmployeeTaskModel(
      id: 'task-1',
      title: 'Prepare campaign artwork',
      description: 'Upload final PNG files.',
      employeeId: 'employee-1',
      assignedBy: 'admin-1',
      status: EmployeeTaskStatus.inProgress,
      projectId: 'project-1',
      priority: TaskPriority.high,
      progress: 65,
      taskType: 'Development',
      labels: ['backend', 'urgent'],
      estimatedHours: 6,
      dueDate: dueDate,
    );

    final json = task.toJson();

    expect(json['employeeId'], 'employee-1');
    expect(json['status'], 'in_progress');
    expect(json['projectId'], 'project-1');
    expect(json['priority'], 'high');
    expect(json['progress'], 65);
    expect(json['dueDate'], isA<Timestamp>());

    final restored = EmployeeTaskModel.fromJson({...json, 'id': 'task-1'});
    expect(restored.priority, TaskPriority.high);
    expect(restored.progress, 65);
    expect(restored.labels, ['backend', 'urgent']);
  });

  test('ProjectModel keeps a safe assigned-team projection', () {
    final startDate = DateTime.utc(2026, 6, 1);
    const project = ProjectModel(
      id: 'project-1',
      name: 'Client Portal',
      client: 'BCreative',
      description: 'Customer self-service portal.',
      department: 'IT & Development',
      category: 'Web',
      priority: ProjectPriority.high,
      status: ProjectStatus.inProgress,
      employeeIds: ['employee-1'],
      teamMembers: [
        ProjectTeamMember(
          employeeId: 'employee-1',
          name: 'Ayesha Khan',
          jobTitle: 'Flutter Developer',
        ),
      ],
    );

    final json = project.toJson(includeCreatedAt: false)
      ..['id'] = project.id
      ..['startDate'] = Timestamp.fromDate(startDate);
    final restored = ProjectModel.fromJson(json);

    expect(restored.id, 'project-1');
    expect(restored.priority, ProjectPriority.high);
    expect(restored.employeeIds, ['employee-1']);
    expect(restored.teamMembers.single.name, 'Ayesha Khan');
    expect(restored.startDate?.toUtc(), startDate);
  });
}
