import 'package:bcreative_ems/features/attendance/models/attendance_record_model.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/payroll/models/payroll_record_model.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only data source for the Super Admin dashboard. Each collection is
/// watched independently so dashboard values update when Firestore changes.
class DashboardRepository {
  DashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<EmployeeModel>> watchEmployees() =>
      _firestore.collection('employees').snapshots().map((snapshot) {
        final employees = snapshot.docs
            .map(EmployeeModel.fromFirestore)
            .toList(growable: false);
        employees.sort(
          (left, right) => left.fullNameLower.compareTo(right.fullNameLower),
        );
        return employees;
      });

  Stream<List<AttendanceRecordModel>> watchAttendanceRecords() => _firestore
      .collection('attendance_records')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(AttendanceRecordModel.fromFirestore)
            .toList(growable: false),
      );

  Stream<List<PayrollRecordModel>> watchPayrollRecords() => _firestore
      .collection('payroll_records')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(PayrollRecordModel.fromFirestore)
            .toList(growable: false),
      );

  Stream<List<ProjectModel>> watchProjects() =>
      _firestore.collection('projects').snapshots().map((snapshot) {
        final projects = snapshot.docs
            .map(ProjectModel.fromFirestore)
            .toList(growable: false);
        projects.sort(
          (left, right) => (left.endDate ?? DateTime(9999)).compareTo(
            right.endDate ?? DateTime(9999),
          ),
        );
        return projects;
      });

  Stream<List<EmployeeTaskModel>> watchTasks() => _firestore
      .collection('tasks')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(EmployeeTaskModel.fromFirestore)
            .toList(growable: false),
      );
}
