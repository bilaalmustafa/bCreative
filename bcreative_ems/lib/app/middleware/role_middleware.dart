import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoleMiddleware extends GetMiddleware {
  RoleMiddleware({required this.allowed});

  final UserRole allowed;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (auth.role != allowed) {
      return RouteSettings(name: auth.homeRoute);
    }
    return null;
  }
}
