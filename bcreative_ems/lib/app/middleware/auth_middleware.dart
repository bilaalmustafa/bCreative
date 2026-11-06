import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (auth.isBootstrapping.value) return null;
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
