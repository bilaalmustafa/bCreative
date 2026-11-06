import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/app/middleware/auth_middleware.dart';
import 'package:bcreative_ems/app/middleware/role_middleware.dart';
import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/features/auth/bindings/auth_binding.dart';
import 'package:bcreative_ems/features/auth/views/login_view.dart';
import 'package:bcreative_ems/features/auth/views/splash_view.dart';
import 'package:bcreative_ems/features/attendance/bindings/attendance_binding.dart';
import 'package:bcreative_ems/features/attendance/views/attendance_management_view.dart';
import 'package:bcreative_ems/features/attendance/views/employee_attendance_view.dart';
import 'package:bcreative_ems/features/dashboard/bindings/dashboard_binding.dart';
import 'package:bcreative_ems/features/dashboard/views/admin_dashboard_view.dart';
import 'package:bcreative_ems/features/dashboard/views/employee_dashboard_view.dart';
import 'package:bcreative_ems/features/employees/bindings/employee_binding.dart';
import 'package:bcreative_ems/features/employees/views/employee_list_view.dart';
import 'package:bcreative_ems/features/profile/bindings/profile_binding.dart';
import 'package:bcreative_ems/features/profile/views/employee_profile_view.dart';
import 'package:bcreative_ems/features/payroll/bindings/payroll_binding.dart';
import 'package:bcreative_ems/features/payroll/views/payroll_management_view.dart';
import 'package:bcreative_ems/features/payroll/views/employee_salary_view.dart';
import 'package:bcreative_ems/features/projects/bindings/project_binding.dart';
import 'package:bcreative_ems/features/projects/views/employee_projects_view.dart';
import 'package:bcreative_ems/features/projects/views/project_management_view.dart';
import 'package:bcreative_ems/features/tasks/bindings/task_binding.dart';
import 'package:bcreative_ems/features/tasks/views/task_list_view.dart';
import 'package:get/get.dart';

abstract final class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardView(),
      binding: DashboardBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.superAdmin),
      ],
    ),
    GetPage(
      name: AppRoutes.employeeDashboard,
      page: () => const EmployeeDashboardView(),
      binding: EmployeeDashboardBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.employee),
      ],
    ),
    GetPage(
      name: AppRoutes.adminEmployees,
      page: () => const EmployeeListView(),
      binding: EmployeeBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.superAdmin),
      ],
    ),
    GetPage(
      name: AppRoutes.adminAttendance,
      page: () => const AttendanceManagementView(),
      binding: AttendanceBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.superAdmin),
      ],
    ),
    GetPage(
      name: AppRoutes.adminPayroll,
      page: () => const PayrollManagementView(),
      binding: PayrollBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.superAdmin),
      ],
    ),
    GetPage(
      name: AppRoutes.adminProjects,
      page: () => const ProjectManagementView(),
      binding: ProjectBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.superAdmin),
      ],
    ),
    GetPage(
      name: AppRoutes.employeeProfile,
      page: () => const EmployeeProfileView(),
      binding: EmployeeProfileBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.employee),
      ],
    ),
    GetPage(
      name: AppRoutes.adminTasks,
      page: () => const TaskListView(),
      binding: TaskBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.superAdmin),
      ],
    ),
    GetPage(
      name: AppRoutes.employeeTasks,
      page: () => const TaskListView(),
      binding: TaskBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.employee),
      ],
    ),
    GetPage(
      name: AppRoutes.employeeProjects,
      page: () => const EmployeeProjectsView(),
      binding: EmployeeProjectsBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.employee),
      ],
    ),
    GetPage(
      name: AppRoutes.employeeAttendance,
      page: () => const EmployeeAttendanceView(),
      binding: EmployeeAttendanceBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.employee),
      ],
    ),
    GetPage(
      name: AppRoutes.employeeSalary,
      page: () => const EmployeeSalaryView(),
      binding: EmployeeSalaryBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowed: UserRole.employee),
      ],
    ),
  ];
}
