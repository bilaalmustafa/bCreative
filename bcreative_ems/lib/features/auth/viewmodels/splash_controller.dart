import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    final auth = Get.find<AuthController>();
    while (auth.isBootstrapping.value) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (!auth.isAuthenticated) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    Get.offAllNamed(auth.homeRoute);
  }
}
