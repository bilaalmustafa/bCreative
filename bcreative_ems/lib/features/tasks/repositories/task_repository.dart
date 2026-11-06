import 'dart:async';

import 'package:bcreative_ems/core/errors/app_exception.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/notifications/models/app_notification_model.dart';
import 'package:bcreative_ems/features/notifications/repositories/notification_repository.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class TaskRepository {
  TaskRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    NotificationRepository? notifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _notifications =
           notifications ?? NotificationRepository(firestore: firestore);

  static const _maxFileSizeBytes = 10 * 1024 * 1024;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final NotificationRepository _notifications;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _updates =>
      _firestore.collection('task_updates');

  Stream<List<EmployeeTaskModel>> watchAll() => _tasks.snapshots().map(
    (snapshot) =>
        _sortTasks(snapshot.docs.map(EmployeeTaskModel.fromFirestore).toList()),
  );

  Stream<List<EmployeeTaskModel>> watchForEmployee(String employeeId) {
    if (employeeId.isEmpty) return Stream.value(const []);
    return _tasks
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map(
          (snapshot) => _sortTasks(
            snapshot.docs.map(EmployeeTaskModel.fromFirestore).toList(),
          ),
        );
  }

  Stream<List<TaskUpdateModel>> watchUpdates({
    required String taskId,
    String? employeeId,
  }) {
    Query<Map<String, dynamic>> query = _updates.where(
      'taskId',
      isEqualTo: taskId,
    );
    if (employeeId != null) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(TaskUpdateModel.fromFirestore).toList(),
        );
  }

  /// Kept unfiltered at the query level so legacy records without `isActive`
  /// are still assignable (the model defaults such records to active).
  Stream<List<EmployeeModel>> watchAssignableEmployees() =>
      _firestore.collection('employees').snapshots().map((snapshot) {
        final employees = snapshot.docs
            .map(EmployeeModel.fromFirestore)
            .where((employee) => employee.isActive)
            .toList();
        employees.sort(
          (left, right) => left.fullNameLower.compareTo(right.fullNameLower),
        );
        return employees;
      });

  Stream<List<ProjectModel>> watchAssignableProjects() =>
      _firestore.collection('projects').snapshots().map((snapshot) {
        final projects = snapshot.docs.map(ProjectModel.fromFirestore).toList();
        projects.sort((left, right) => left.name.compareTo(right.name));
        return projects;
      });

  Future<List<EmployeeModel>> fetchAssignableEmployees() =>
      watchAssignableEmployees().first;

  Future<List<ProjectModel>> fetchAssignableProjects() =>
      watchAssignableProjects().first;

  Future<void> createTask(EmployeeTaskModel task) async {
    final actorUid = _requireActorUid();
    final document = _tasks.doc();
    final assignedTask = EmployeeTaskModel(
      id: document.id,
      title: task.title,
      description: task.description,
      employeeId: task.employeeId,
      assignedBy: actorUid,
      status: task.status,
      projectId: task.projectId,
      priority: task.priority,
      progress: task.progress,
      taskType: task.taskType,
      labels: task.labels,
      estimatedHours: task.estimatedHours,
      dueDate: task.dueDate,
    );
    final batch = _firestore.batch();
    batch.set(document, assignedTask.toJson(includeCreatedAt: true));
    _notifications.addEmployeeNotification(
      batch,
      employeeId: assignedTask.employeeId,
      actorId: actorUid,
      type: AppNotificationType.taskAssigned,
      title: 'New task assigned',
      body: 'You have been assigned "${assignedTask.title.trim()}".',
      referenceId: assignedTask.id,
    );
    await batch.commit();
  }

  Future<void> updateTask(EmployeeTaskModel task) async {
    if (task.id.isEmpty) {
      throw const ValidationException('Select a task before updating it.');
    }
    final actorUid = _requireActorUid();
    final document = _tasks.doc(task.id);
    final existing = await document.get();
    final previousEmployeeId = existing.data()?['employeeId'] as String?;
    final batch = _firestore.batch();
    batch.update(document, task.toJson());
    if (previousEmployeeId != task.employeeId) {
      _notifications.addEmployeeNotification(
        batch,
        employeeId: task.employeeId,
        actorId: actorUid,
        type: AppNotificationType.taskAssigned,
        title: 'Task assigned to you',
        body: 'You have been assigned "${task.title.trim()}".',
        referenceId: task.id,
      );
    }
    await batch.commit();
  }

  Future<void> deleteTask(String taskId) async {
    if (taskId.isEmpty) return;
    await _tasks.doc(taskId).delete();
  }

  Future<void> updateTaskStatus({
    required EmployeeTaskModel task,
    required EmployeeTaskStatus status,
  }) => updateTaskProgress(
    task: task,
    status: status,
    progress: switch (status) {
      EmployeeTaskStatus.assigned => 0,
      EmployeeTaskStatus.inProgress => task.progress.clamp(1, 99),
      EmployeeTaskStatus.completed => 100,
    },
  );

  Future<void> updateTaskProgress({
    required EmployeeTaskModel task,
    required EmployeeTaskStatus status,
    required int progress,
  }) async {
    final actorUid = _requireActorUid();
    final employeeName = await _employeeName(task.employeeId);
    final normalizedProgress = progress.clamp(0, 100);
    final batch = _firestore.batch();
    batch.update(_tasks.doc(task.id), {
      'status': status.value,
      'progress': normalizedProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _notifications.addAdminNotification(
      batch,
      actorId: actorUid,
      type: AppNotificationType.taskProgress,
      title: 'Task progress updated',
      body:
          '$employeeName updated "${task.title}" to ${_statusLabel(status)} ($normalizedProgress%).',
      referenceId: task.id,
    );
    await batch.commit();
  }

  Future<void> createUpdate({
    required String taskId,
    required String employeeId,
    required String text,
    PlatformFile? file,
  }) async {
    final actorUid = _requireActorUid();
    final trimmedText = text.trim();
    if (trimmedText.isEmpty && file == null) {
      throw const ValidationException('Write an update or attach a file.');
    }
    if (file != null) _validateFile(file);

    final document = _updates.doc();
    Reference? fileReference;
    try {
      if (file != null) {
        fileReference = _storage.ref(
          'task_attachments/$employeeId/$taskId/${document.id}/${file.name}',
        );
        await fileReference.putData(
          file.bytes!,
          SettableMetadata(contentType: _contentTypeFor(file.name)),
        );
      }
      final taskSnapshot = await _tasks.doc(taskId).get();
      final taskTitle = taskSnapshot.data()?['title'] as String? ?? 'a task';
      final employeeName = await _employeeName(employeeId);
      final batch = _firestore.batch();
      batch.set(
        document,
        TaskUpdateModel(
          id: document.id,
          taskId: taskId,
          employeeId: employeeId,
          text: trimmedText,
          fileName: file?.name,
          storagePath: fileReference?.fullPath,
        ).toJson(includeCreatedAt: true),
      );
      _notifications.addAdminNotification(
        batch,
        actorId: actorUid,
        type: AppNotificationType.taskActivity,
        title: 'New task activity',
        body: '$employeeName posted an update on "$taskTitle".',
        referenceId: taskId,
      );
      await batch.commit();
    } catch (_) {
      if (fileReference != null) {
        try {
          await fileReference.delete();
        } catch (_) {
          // Preserve the original failure if Storage cleanup also fails.
        }
      }
      rethrow;
    }
  }

  Future<void> updateUpdateText(TaskUpdateModel update, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty && !update.hasFile) {
      throw const ValidationException(
        'An update needs text or an attached file.',
      );
    }
    return _updates.doc(update.id).update({
      'text': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUpdate(TaskUpdateModel update) async {
    if (update.hasFile) {
      try {
        await _storage.ref(update.storagePath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }
    await _updates.doc(update.id).delete();
  }

  Future<String?> getDownloadUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    return _storage.ref(storagePath).getDownloadURL();
  }

  String _requireActorUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthException('You must be signed in.');
    return uid;
  }

  Future<String> _employeeName(String employeeId) async {
    final profile = await _firestore
        .collection('employee_profiles')
        .doc(employeeId)
        .get();
    final name = profile.data()?['fullName'] as String?;
    return name?.trim().isNotEmpty == true ? name!.trim() : 'An employee';
  }

  String _statusLabel(EmployeeTaskStatus status) => switch (status) {
    EmployeeTaskStatus.assigned => 'Pending',
    EmployeeTaskStatus.inProgress => 'In progress',
    EmployeeTaskStatus.completed => 'Completed',
  };

  void _validateFile(PlatformFile file) {
    final bytes = file.bytes;
    if (bytes == null || bytes.lengthInBytes > _maxFileSizeBytes) {
      throw const ValidationException('Choose a file smaller than 10 MB.');
    }
    if (_contentTypeFor(file.name) == null) {
      throw const ValidationException(
        'Only PDF, TXT, PNG, and JPG files are allowed.',
      );
    }
  }

  String? _contentTypeFor(String fileName) {
    final file = fileName.toLowerCase();
    if (file.endsWith('.pdf')) return 'application/pdf';
    if (file.endsWith('.txt')) return 'text/plain';
    if (file.endsWith('.png')) return 'image/png';
    if (file.endsWith('.jpg') || file.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  List<EmployeeTaskModel> _sortTasks(List<EmployeeTaskModel> tasks) {
    tasks.sort(
      (left, right) => (right.updatedAt ?? right.createdAt ?? DateTime(0))
          .compareTo(left.updatedAt ?? left.createdAt ?? DateTime(0)),
    );
    return tasks;
  }
}
