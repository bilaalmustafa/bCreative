import 'package:bcreative_ems/core/services/auth_service.dart';
import 'package:bcreative_ems/core/services/session_preferences.dart';
import 'package:bcreative_ems/features/auth/repositories/auth_repository.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/notifications/repositories/notification_repository.dart';
import 'package:bcreative_ems/features/notifications/viewmodels/notification_controller.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
    Get.put(SessionPreferences(), permanent: true);
    Get.put(AuthRepository(Get.find<AuthService>()), permanent: true);
    Get.put(
      AuthController(
        Get.find<AuthRepository>(),
        Get.find<SessionPreferences>(),
      ),
      permanent: true,
    );
    Get.put(NotificationRepository(), permanent: true);
    Get.put(
      NotificationController(
        Get.find<NotificationRepository>(),
        Get.find<AuthController>(),
      ),
      permanent: true,
    );
  }
}
