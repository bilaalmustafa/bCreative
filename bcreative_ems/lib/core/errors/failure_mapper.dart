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
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'Permission was denied. Please sign out, sign in again, and retry.',
        'unavailable' => 'Service is temporarily unavailable. Check your internet connection and try again.',
        'deadline-exceeded' => 'The request timed out. Please try again.',
        'already-exists' => 'Today\'s attendance record already exists.',
        'failed-precondition' => 'This action cannot be completed right now. Please refresh and try again.',
        _ => 'Something went wrong. Please try again.',
      };
    }
    if (error is StateError) {
      return error.message.toString();
    }

    // Some web/plugin failures arrive as a plain JavaScript/Platform error
    // rather than FirebaseException. Keep common Firestore failures useful
    // to the employee instead of collapsing them into a generic popup.
    final text = error.toString().toLowerCase();
    if (text.contains('permission-denied') ||
        text.contains('permission denied') ||
        text.contains('insufficient permissions')) {
      return 'Permission was denied. Please sign out, sign in again, and retry.';
    }
    if (text.contains('failed-precondition') ||
        text.contains('requires an index')) {
      return 'Attendance data is still being prepared. Please refresh and try again.';
    }
    if (text.contains('network') || text.contains('offline')) {
      return 'Check your internet connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
