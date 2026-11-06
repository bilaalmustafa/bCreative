import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/auth/repositories/auth_repository.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  LoginController(this._repository);

  final AuthRepository _repository;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    if (!GetUtils.isEmail(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> signIn() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      final authSession = await _repository.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      final auth = Get.find<AuthController>();

      if (authSession.role == UserRole.unknown) {
        Get.snackbar(
          'Access denied',
          'Your account has no assigned role. Contact your administrator.',
          snackPosition: SnackPosition.BOTTOM,
        );
        await auth.signOut();
        return;
      }

      await auth.setAuthenticatedSession(authSession);
      Get.offAllNamed(auth.homeRoute);
    } catch (e) {
      Get.snackbar(
        'Sign in failed',
        FailureMapper.message(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Email required',
        'Enter your email above, then tap Forgot password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      await _repository.resetPassword(email);
      Get.snackbar(
        'Email sent',
        'Check your inbox for password reset instructions.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Reset failed',
        FailureMapper.message(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
