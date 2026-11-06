import 'package:bcreative_ems/core/errors/app_exception.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/notifications/models/app_notification_model.dart';
import 'package:bcreative_ems/features/notifications/repositories/notification_repository.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectRepository {
  ProjectRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationRepository? notifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _notifications =
           notifications ?? NotificationRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationRepository _notifications;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _firestore.collection('projects');

  Stream<List<ProjectModel>> watchAllProjects() => _projects.snapshots().map(
    (snapshot) =>
        _sortProjects(snapshot.docs.map(ProjectModel.fromFirestore).toList()),
  );

  /// The query mirrors the Firestore security predicate. An employee can only
  /// ever subscribe to projects whose `employeeIds` contains their own id.
  Stream<List<ProjectModel>> watchProjectsForEmployee(String employeeId) {
    if (employeeId.isEmpty) return Stream.value(const []);
    return _projects
        .where('employeeIds', arrayContains: employeeId)
        .snapshots()
        .map(
          (snapshot) => _sortProjects(
            snapshot.docs.map(ProjectModel.fromFirestore).toList(),
          ),
        );
  }

  Stream<List<EmployeeTaskModel>> watchAllTasks() => _firestore
      .collection('tasks')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(EmployeeTaskModel.fromFirestore).toList()..sort(
              (left, right) => (right.updatedAt ?? DateTime(0)).compareTo(
                left.updatedAt ?? DateTime(0),
              ),
            ),
      );

  Stream<List<EmployeeTaskModel>> watchTasksForEmployee(String employeeId) {
    if (employeeId.isEmpty) return Stream.value(const []);
    return _firestore
        .collection('tasks')
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(EmployeeTaskModel.fromFirestore).toList()..sort(
                (left, right) => (right.updatedAt ?? DateTime(0)).compareTo(
                  left.updatedAt ?? DateTime(0),
                ),
              ),
        );
  }

  /// Read the directory first, then filter in Dart. Older employee documents
  /// may not have an `isActive` field; [EmployeeModel] treats those as active.
  /// A Firestore `where(isActive == true)` query would silently omit them and
  /// leave the project team picker empty.
  Stream<List<EmployeeModel>> watchActiveEmployees() =>
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

  Future<List<EmployeeModel>> fetchActiveEmployees() =>
      watchActiveEmployees().first;

  Future<void> createProject(ProjectModel project) async {
    final actorUid = _auth.currentUser?.uid;
    if (actorUid == null) throw const AuthException('You must be signed in.');
    final document = _projects.doc();
    final assignedProject = project.copyWith(
      id: document.id,
      createdBy: actorUid,
    );
    final batch = _firestore.batch();
    batch.set(document, assignedProject.toJson(includeCreatedAt: true));
    for (final employeeId in assignedProject.employeeIds) {
      _notifications.addEmployeeNotification(
        batch,
        employeeId: employeeId,
        actorId: actorUid,
        type: AppNotificationType.projectAssigned,
        title: 'New project assignment',
        body: 'You have been added to "${assignedProject.name.trim()}".',
        referenceId: assignedProject.id,
      );
    }
    await batch.commit();
  }

  Future<void> updateProject(ProjectModel project) async {
    if (project.id.isEmpty) {
      throw const ValidationException('Select a project before updating it.');
    }
    final actorUid = _auth.currentUser?.uid;
    if (actorUid == null) throw const AuthException('You must be signed in.');
    final document = _projects.doc(project.id);
    final existing = await document.get();
    final previousEmployeeIds = List<String>.from(
      existing.data()?['employeeIds'] as List<dynamic>? ?? const <dynamic>[],
    );
    final newlyAssigned = project.employeeIds.where(
      (employeeId) => !previousEmployeeIds.contains(employeeId),
    );
    final batch = _firestore.batch();
    batch.update(document, project.toJson());
    for (final employeeId in newlyAssigned) {
      _notifications.addEmployeeNotification(
        batch,
        employeeId: employeeId,
        actorId: actorUid,
        type: AppNotificationType.projectAssigned,
        title: 'Project assignment updated',
        body: 'You have been added to "${project.name.trim()}".',
        referenceId: project.id,
      );
    }
    await batch.commit();
  }

  Future<void> deleteProject(String projectId) async {
    if (projectId.isEmpty) return;
    await _projects.doc(projectId).delete();
  }

  List<ProjectModel> _sortProjects(List<ProjectModel> projects) {
    projects.sort(
      (left, right) => (right.updatedAt ?? right.createdAt ?? DateTime(0))
          .compareTo(left.updatedAt ?? left.createdAt ?? DateTime(0)),
    );
    return projects;
  }
}
