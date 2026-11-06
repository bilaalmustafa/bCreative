import 'package:bcreative_ems/core/errors/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract final class FailureMapper {
  static String message(Object error) {
    if (error is AppException) return error.message;
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' => 'Invalid email or password.',
        'user-disabled' => 'This account has been deactivated.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'invalid-email' => 'Please enter a valid email address.',
        'email-already-in-use' =>
          'An Auth account already exists for this email address.',
        'weak-password' => 'Choose a stronger temporary password.',
        _ => 'Sign-in failed. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}
