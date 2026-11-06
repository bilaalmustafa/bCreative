import 'package:bcreative_ems/features/auth/repositories/auth_repository.dart';
import 'package:bcreative_ems/features/auth/viewmodels/login_controller.dart';
import 'package:bcreative_ems/features/auth/viewmodels/splash_controller.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<AuthRepository>()),
    );
  }
}

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(SplashController());
  }
}
